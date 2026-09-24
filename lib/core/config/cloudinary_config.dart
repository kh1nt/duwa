/// Cloudinary Media Pipeline Configuration for DUWA
///
/// Handles high-performance unsigned image uploads and dynamic responsive CDN
/// transformations for player avatars, custom game box art, and squad banners.
///
/// Credentials can be set at compile time (`--dart-define=CLOUDINARY_CLOUD_NAME=...`),
/// modified in code via defaults, or updated at runtime via the in-app Media Storage drawer.
class CloudinaryConfig {
  /// Default Cloudinary cloud name
  static const String defaultCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dz4x2mmzc',
  );

  /// Default unsigned upload preset (configured in Cloudinary Console -> Settings -> Upload)
  static const String defaultUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'duwa_preset',
  );

  /// Cloudinary API Base Upload URL
  static String uploadUrl(String cloudName) =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Cloudinary CDN Host check
  static bool isCloudinaryUrl(String url) => url.contains('res.cloudinary.com');
}
