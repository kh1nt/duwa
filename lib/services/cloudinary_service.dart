import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/cloudinary_config.dart';
import 'preferences_service.dart';

/// Production Cloudinary media pipeline:
/// - Direct unsigned client upload for user avatars, squad banners, and game box art.
/// - Dynamic responsive CDN URL transformations (f_auto, q_auto, width/height cropping).
/// - Resilient fallback to preferences and CloudinaryConfig defaults.
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  String? _customCloudName;
  String? _customUploadPreset;

  /// Effective Cloudinary cloud name (Preferences -> In-memory override -> CloudinaryConfig default)
  String get cloudName {
    if (_customCloudName != null && _customCloudName!.isNotEmpty) {
      return _customCloudName!;
    }
    final saved = PreferencesService().getCloudinaryCloudName();
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    return CloudinaryConfig.defaultCloudName;
  }

  set cloudName(String value) {
    _customCloudName = value.trim();
  }

  /// Effective Cloudinary unsigned upload preset
  String get uploadPreset {
    if (_customUploadPreset != null && _customUploadPreset!.isNotEmpty) {
      return _customUploadPreset!;
    }
    final saved = PreferencesService().getCloudinaryUploadPreset();
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    return CloudinaryConfig.defaultUploadPreset;
  }

  set uploadPreset(String value) {
    _customUploadPreset = value.trim();
  }

  /// Track last error for user-facing diagnosis
  String? lastErrorMessage;

  /// Initialize with custom credentials
  void configure({required String cloudName, required String uploadPreset}) {
    _customCloudName = cloudName.trim();
    _customUploadPreset = uploadPreset.trim();
  }

  /// Reset to compiled defaults
  void resetToDefaults() {
    _customCloudName = null;
    _customUploadPreset = null;
    PreferencesService().setCloudinaryCloudName(null);
    PreferencesService().setCloudinaryUploadPreset(null);
  }

  /// Whether Cloudinary credentials are set up
  bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  /// Test connection by attempting a lightweight 1x1 pixel upload
  Future<bool> testConnection() async {
    lastErrorMessage = null;
    try {
      // 1x1 transparent PNG bytes
      final testPngBytes = Uint8List.fromList(const [
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0,
        0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1,
        13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
      ]);

      final url = await uploadImageBytes(
        bytes: testPngBytes,
        filename: 'duwa_ping_test.png',
        folder: 'duwa/tests',
      );
      return url != null && url.isNotEmpty;
    } catch (e) {
      lastErrorMessage = e.toString();
      return false;
    }
  }

  /// Upload raw image bytes directly to Cloudinary
  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'duwa/avatars',
  }) async {
    lastErrorMessage = null;
    try {
      final activeCloud = cloudName;
      final activePreset = uploadPreset;

      if (activeCloud.isEmpty || activePreset.isEmpty) {
        lastErrorMessage = 'Cloudinary credentials missing (cloudName or preset empty)';
        debugPrint(lastErrorMessage);
        return null;
      }

      final uri = Uri.parse(CloudinaryConfig.uploadUrl(activeCloud));
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = activePreset
        ..fields['folder'] = folder
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename.isNotEmpty ? filename : 'upload.jpg',
        ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        debugPrint('Cloudinary upload success: $secureUrl');
        return secureUrl;
      } else {
        lastErrorMessage = 'Upload failed (${response.statusCode}): ${response.body}';
        debugPrint('Cloudinary upload error (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      lastErrorMessage = 'Upload error: $e';
      debugPrint('Cloudinary upload exception: $e');
      return null;
    }
  }

  /// Formats any Cloudinary URL into an ultra-fast, optimized format
  /// with automatic format negotiation (AVIF/WebP) and automatic quality compression.
  String getOptimizedUrl(
    String rawUrl, {
    int? width,
    int? height,
    String crop = 'fill',
    int quality = 80,
  }) {
    if (rawUrl.isEmpty) return rawUrl;
    if (!rawUrl.contains('res.cloudinary.com')) return rawUrl;

    const uploadToken = '/upload/';
    final tokenIndex = rawUrl.indexOf(uploadToken);
    if (tokenIndex == -1) return rawUrl;

    final transformations = <String>['f_auto', 'q_auto'];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (width != null || height != null) transformations.add('c_$crop');

    final transformStr = transformations.join(',');
    final prefix = rawUrl.substring(0, tokenIndex + uploadToken.length);
    final suffix = rawUrl.substring(tokenIndex + uploadToken.length);

    return '$prefix$transformStr/$suffix';
  }
}
