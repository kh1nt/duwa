import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Production Cloudinary media pipeline:
/// - Direct unsigned client upload for user avatars, squad banners, and session photos.
/// - Dynamic responsive CDN URL transformations (f_auto, q_auto, width/height cropping).
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  /// Cloudinary cloud name (can be configured by caller or environment)
  String cloudName = 'duwa';

  /// Cloudinary unsigned upload preset (configured in Cloudinary Console -> Settings -> Upload)
  String uploadPreset = 'duwa_preset';

  /// Initialize with custom credentials
  void configure({required String cloudName, required String uploadPreset}) {
    this.cloudName = cloudName;
    this.uploadPreset = uploadPreset;
  }

  /// Whether Cloudinary credentials are set up
  bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  /// Upload raw image bytes directly to Cloudinary
  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'duwa/avatars',
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        debugPrint('Cloudinary upload success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Cloudinary upload error (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
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
