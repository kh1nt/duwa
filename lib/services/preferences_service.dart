import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local persistence service for DUWA.
/// Handles theme vibe persistence, offline profile caching, and local settings.
class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  static const String _keyThemeVibe = 'duwa_theme_vibe';
  static const String _keyCachedProfile = 'duwa_cached_user_profile';
  static const String _keyDismissedNotifs = 'duwa_dismissed_notifications';
  static const String _keySteamApiKey = 'duwa_steam_api_key';
  static const String _keySteamInputId = 'duwa_steam_input_id';
  static const String _keyCloudinaryCloudName = 'duwa_cloudinary_cloud_name';
  static const String _keyCloudinaryUploadPreset = 'duwa_cloudinary_upload_preset';
  static const String _keyCustomGames = 'duwa_custom_games';

  /// In-memory fallback map for unit test environments or before initialization
  final Map<String, dynamic> _fallbackMemory = {};

  /// Initialize SharedPreferences instance (called in main)
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('PreferencesService init note (test or fallback mode): $e');
    }
  }

  /// Inject mock/test preferences
  @visibleForTesting
  void setMockPreferences(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // ==========================================
  // --- THEME VIBE PERSISTENCE ---
  // ==========================================

  /// Get the saved theme vibe name (e.g. 'obsidianVoid', 'cleanLight')
  String? getThemeVibe() {
    if (_prefs != null) {
      return _prefs!.getString(_keyThemeVibe);
    }
    return _fallbackMemory[_keyThemeVibe] as String?;
  }

  /// Persist the selected theme vibe
  Future<void> setThemeVibe(String vibeName) async {
    _fallbackMemory[_keyThemeVibe] = vibeName;
    try {
      if (_prefs != null) {
        await _prefs!.setString(_keyThemeVibe, vibeName);
      }
    } catch (e) {
      debugPrint('Error saving theme vibe: $e');
    }
  }

  // ==========================================
  // --- OFFLINE PROFILE CACHE ---
  // ==========================================

  /// Get cached user profile for instant launch without network delay
  Map<String, dynamic>? getCachedUserProfile([String? uid]) {
    try {
      final key = uid != null && uid.isNotEmpty ? '${_keyCachedProfile}_$uid' : _keyCachedProfile;
      final jsonStr = _prefs != null
          ? _prefs!.getString(key)
          : _fallbackMemory[key] as String?;
      if (jsonStr == null || jsonStr.isEmpty) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading cached profile: $e');
      return null;
    }
  }

  /// Cache user profile locally
  Future<void> setCachedUserProfile(Map<String, dynamic> profileMap, [String? uid]) async {
    try {
      final jsonStr = jsonEncode(profileMap);
      _fallbackMemory[_keyCachedProfile] = jsonStr;
      if (uid != null && uid.isNotEmpty) {
        _fallbackMemory['${_keyCachedProfile}_$uid'] = jsonStr;
      }
      if (_prefs != null) {
        await _prefs!.setString(_keyCachedProfile, jsonStr);
        if (uid != null && uid.isNotEmpty) {
          await _prefs!.setString('${_keyCachedProfile}_$uid', jsonStr);
        }
      }
    } catch (e) {
      debugPrint('Error caching user profile: $e');
    }
  }

  // ==========================================
  // --- DISMISSED / READ NOTIFICATIONS ---
  // ==========================================

  /// Get set of notification IDs marked as read locally
  Set<String> getReadNotificationIds() {
    if (_prefs != null) {
      final list = _prefs!.getStringList(_keyDismissedNotifs) ?? [];
      return list.toSet();
    }
    final list = _fallbackMemory[_keyDismissedNotifs] as List<String>? ?? [];
    return list.toSet();
  }

  /// Persist set of read notification IDs
  Future<void> markNotificationRead(String notifId) async {
    final current = getReadNotificationIds()..add(notifId);
    _fallbackMemory[_keyDismissedNotifs] = current.toList();
    try {
      if (_prefs != null) {
        await _prefs!.setStringList(_keyDismissedNotifs, current.toList());
      }
    } catch (e) {
      debugPrint('Error persisting read notification: $e');
    }
  }

  // ==========================================
  // --- STEAM INTEGRATION CONFIG ---
  // ==========================================

  /// Retrieve locally saved Steam Web API Key
  String? getSteamApiKey() {
    if (_prefs != null) {
      return _prefs!.getString(_keySteamApiKey);
    }
    return _fallbackMemory[_keySteamApiKey] as String?;
  }

  /// Persist user-entered Steam Web API Key
  Future<void> setSteamApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      _fallbackMemory.remove(_keySteamApiKey);
      if (_prefs != null) await _prefs!.remove(_keySteamApiKey);
      return;
    }
    final trimmed = key.trim();
    _fallbackMemory[_keySteamApiKey] = trimmed;
    try {
      if (_prefs != null) {
        await _prefs!.setString(_keySteamApiKey, trimmed);
      }
    } catch (e) {
      debugPrint('Error saving steam API key: $e');
    }
  }

  /// Retrieve locally saved Steam Friend Code or SteamID
  String? getSteamInputId() {
    if (_prefs != null) {
      return _prefs!.getString(_keySteamInputId);
    }
    return _fallbackMemory[_keySteamInputId] as String?;
  }

  /// Persist user-entered Steam Friend Code or SteamID
  Future<void> setSteamInputId(String? inputId) async {
    if (inputId == null || inputId.trim().isEmpty) {
      _fallbackMemory.remove(_keySteamInputId);
      if (_prefs != null) await _prefs!.remove(_keySteamInputId);
      return;
    }
    final trimmed = inputId.trim();
    _fallbackMemory[_keySteamInputId] = trimmed;
    try {
      if (_prefs != null) {
        await _prefs!.setString(_keySteamInputId, trimmed);
      }
    } catch (e) {
      debugPrint('Error saving steam input id: $e');
    }
  }

  // ==========================================
  // --- CLOUDINARY MEDIA CONFIG ---
  // ==========================================

  /// Retrieve custom configured Cloudinary cloud name
  String? getCloudinaryCloudName() {
    if (_prefs != null) {
      return _prefs!.getString(_keyCloudinaryCloudName);
    }
    return _fallbackMemory[_keyCloudinaryCloudName] as String?;
  }

  /// Save custom Cloudinary cloud name
  Future<void> setCloudinaryCloudName(String? name) async {
    if (name == null || name.trim().isEmpty) {
      _fallbackMemory.remove(_keyCloudinaryCloudName);
      if (_prefs != null) await _prefs!.remove(_keyCloudinaryCloudName);
      return;
    }
    final trimmed = name.trim();
    _fallbackMemory[_keyCloudinaryCloudName] = trimmed;
    try {
      if (_prefs != null) {
        await _prefs!.setString(_keyCloudinaryCloudName, trimmed);
      }
    } catch (e) {
      debugPrint('Error saving Cloudinary cloud name: $e');
    }
  }

  /// Retrieve custom configured Cloudinary upload preset
  String? getCloudinaryUploadPreset() {
    if (_prefs != null) {
      return _prefs!.getString(_keyCloudinaryUploadPreset);
    }
    return _fallbackMemory[_keyCloudinaryUploadPreset] as String?;
  }

  /// Save custom Cloudinary upload preset
  Future<void> setCloudinaryUploadPreset(String? preset) async {
    if (preset == null || preset.trim().isEmpty) {
      _fallbackMemory.remove(_keyCloudinaryUploadPreset);
      if (_prefs != null) await _prefs!.remove(_keyCloudinaryUploadPreset);
      return;
    }
    final trimmed = preset.trim();
    _fallbackMemory[_keyCloudinaryUploadPreset] = trimmed;
    try {
      if (_prefs != null) {
        await _prefs!.setString(_keyCloudinaryUploadPreset, trimmed);
      }
    } catch (e) {
      debugPrint('Error saving Cloudinary upload preset: $e');
    }
  }

  // ==========================================
  // --- LOCAL CUSTOM GAMES CACHE ---
  // ==========================================

  /// Retrieve list of cached custom added games for instant offline startup
  List<Map<String, dynamic>> getCachedCustomGames() {
    try {
      final jsonStr = _prefs != null
          ? _prefs!.getString(_keyCustomGames)
          : _fallbackMemory[_keyCustomGames] as String?;
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error loading cached custom games: $e');
      return [];
    }
  }

  /// Persist custom games locally
  Future<void> setCachedCustomGames(List<Map<String, dynamic>> games) async {
    try {
      final jsonStr = jsonEncode(games);
      _fallbackMemory[_keyCustomGames] = jsonStr;
      if (_prefs != null) {
        await _prefs!.setString(_keyCustomGames, jsonStr);
      }
    } catch (e) {
      debugPrint('Error caching custom games: $e');
    }
  }

  /// Clear all cached user session data (used on sign-out)
  /// Wipes profile cache and read notification lists while preserving theme preference.
  Future<void> clearUserSessionData() async {
    _fallbackMemory.remove(_keyCachedProfile);
    _fallbackMemory.remove(_keyDismissedNotifs);
    _fallbackMemory.removeWhere((key, _) => key.startsWith(_keyCachedProfile));
    try {
      if (_prefs != null) {
        await _prefs!.remove(_keyCachedProfile);
        await _prefs!.remove(_keyDismissedNotifs);
        final allKeys = _prefs!.getKeys();
        for (final k in allKeys) {
          if (k.startsWith(_keyCachedProfile)) {
            await _prefs!.remove(k);
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing user session preferences: $e');
    }
  }

  /// Clear all cached data (used on full reset)
  Future<void> clearAll() async {
    _fallbackMemory.clear();
    try {
      if (_prefs != null) {
        await _prefs!.clear();
      }
    } catch (e) {
      debugPrint('Error clearing preferences: $e');
    }
  }
}
