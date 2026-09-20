/// Steam Integration Configuration
///
/// DUWA connects directly to Valve's Steam Web API to sync player profiles,
/// game libraries, playtime hours, and official high-resolution CDN key art.
///
/// ### How to get a Steam Web API Key (Free):
/// 1. Go to https://steamcommunity.com/dev/apikey
/// 2. Sign in with your Steam account
/// 3. Enter any domain name (e.g., "duwa.app" or "localhost") and generate your key
///
/// ### How to provide the API Key:
/// - **Option A (In Code / File)**: Paste your key into [steamApiKey] below.
/// - **Option B (Command Line Flag)**: Run flutter with `--dart-define=STEAM_API_KEY=YOUR_KEY`
/// - **Option C (In-App UI)**: Paste it directly inside DUWA in Profile -> Steam Sync
class SteamConfig {
  /// Compile-time or hardcoded Steam Web API Key.
  /// If empty, DUWA will look for a key saved in local device settings (UI),
  /// or prompt the player to paste one.
  static const String steamApiKey = String.fromEnvironment(
    'STEAM_API_KEY',
    // Paste your Steam Web API Key here if you want to hardcode it for development:
    defaultValue: 'D715B46C6D4975AF395A9BEFE5AD1799',
  );

  /// Base URL for Valve's official Steam Web API
  static const String apiBaseUrl = 'https://api.steampowered.com';

  /// Base URL for official Steam CDN capsule/header artwork
  static const String cdnArtworkBase = 'https://cdn.cloudflare.steamstatic.com/steam/apps';

  /// Standard 64-bit Steam ID base offset for converting 32-bit Friend Codes / Account IDs
  /// SteamID64 = 76561197960265728 + AccountID (Friend Code)
  static final BigInt steamIdOffset = BigInt.parse('76561197960265728');
}
