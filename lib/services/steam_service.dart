import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/steam_config.dart';
import '../models/game_model.dart';

/// Data class representing a player's public Steam profile
class SteamPlayerProfile {
  final String steamId;
  final String personaName;
  final String avatarUrl;
  final String profileUrl;
  final int personaState;
  final String? currentGameTitle;

  const SteamPlayerProfile({
    required this.steamId,
    required this.personaName,
    required this.avatarUrl,
    required this.profileUrl,
    required this.personaState,
    this.currentGameTitle,
  });

  bool get isOnline => personaState > 0;

  String get statusText {
    if (currentGameTitle != null && currentGameTitle!.isNotEmpty) {
      return 'Playing $currentGameTitle';
    }
    switch (personaState) {
      case 1:
        return 'Online';
      case 2:
        return 'Busy';
      case 3:
        return 'Away';
      case 4:
        return 'Snooze';
      case 5:
        return 'Looking to trade';
      case 6:
        return 'Looking to play';
      default:
        return 'Offline';
    }
  }

  factory SteamPlayerProfile.fromMap(Map<String, dynamic> map) {
    return SteamPlayerProfile(
      steamId: map['steamid']?.toString() ?? '',
      personaName: map['personaname']?.toString() ?? 'Steam Player',
      avatarUrl: map['avatarfull']?.toString() ??
          map['avatarmedium']?.toString() ??
          map['avatar']?.toString() ??
          '',
      profileUrl: map['profileurl']?.toString() ?? '',
      personaState: (map['personastate'] as num?)?.toInt() ?? 0,
      currentGameTitle: map['gameextrainfo']?.toString(),
    );
  }
}

/// Result envelope for Steam sync operations
class SteamSyncResult {
  final bool isSuccess;
  final String? errorMessage;
  final SteamPlayerProfile? profile;
  final List<GameModel> games;

  const SteamSyncResult({
    required this.isSuccess,
    this.errorMessage,
    this.profile,
    this.games = const [],
  });

  factory SteamSyncResult.success({
    required SteamPlayerProfile profile,
    required List<GameModel> games,
  }) =>
      SteamSyncResult(
        isSuccess: true,
        profile: profile,
        games: games,
      );

  factory SteamSyncResult.failure(String message) => SteamSyncResult(
        isSuccess: false,
        errorMessage: message,
      );
}

/// Production Steam Web API Engine
/// Connects DUWA to Valve's live Web API to sync player identities, game libraries,
/// and official Steam CDN key art.
class SteamService {
  static final SteamService _instance = SteamService._internal();
  factory SteamService() => _instance;
  SteamService._internal();

  /// Converts any user input (Friend Code, SteamID64, or Custom Vanity URL)
  /// into a verified 64-bit Steam ID string.
  Future<String?> resolveSteamId(
    String input, {
    required String apiKey,
    http.Client? client,
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Pattern 1: Direct 17-digit SteamID64 (starts with 765611)
    if (RegExp(r'^765611\d{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    // Pattern 2: Steam Profile URL containing SteamID64
    final profileMatch =
        RegExp(r'steamcommunity\.com/profiles/(765611\d{11})').firstMatch(trimmed);
    if (profileMatch != null) {
      return profileMatch.group(1);
    }

    // Pattern 3: Steam Friend Code / 32-bit Account ID (all digits, up to 10 chars)
    if (RegExp(r'^\d{4,10}$').hasMatch(trimmed)) {
      try {
        final friendCodeBig = BigInt.parse(trimmed);
        final steamId64 = SteamConfig.steamIdOffset + friendCodeBig;
        return steamId64.toString();
      } catch (_) {
        // Fallthrough if parsing fails
      }
    }

    // Pattern 4: Vanity URL (e.g. steamcommunity.com/id/gaben or just "gaben")
    String vanity = trimmed;
    final vanityMatch =
        RegExp(r'steamcommunity\.com/id/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (vanityMatch != null) {
      vanity = vanityMatch.group(1)!;
    }

    // Resolve vanity name via Valve API
    if (apiKey.trim().isNotEmpty) {
      try {
        final httpClient = client ?? http.Client();
        final url = Uri.parse(
          '${SteamConfig.apiBaseUrl}/ISteamUser/ResolveVanityURL/v0001/?key=$apiKey&vanityurl=$vanity',
        );
        final res = await httpClient.get(url);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final responseObj = data['response'] as Map<String, dynamic>?;
          if (responseObj != null && responseObj['success'] == 1) {
            return responseObj['steamid']?.toString();
          }
        }
      } catch (e) {
        debugPrint('Error resolving Steam vanity URL: $e');
      }
    }

    return null;
  }

  /// Fetches public player profile information from Steam
  Future<SteamPlayerProfile?> fetchPlayerProfile(
    String steamId64, {
    required String apiKey,
    http.Client? client,
  }) async {
    if (apiKey.trim().isEmpty || steamId64.trim().isEmpty) return null;

    try {
      final httpClient = client ?? http.Client();
      final url = Uri.parse(
        '${SteamConfig.apiBaseUrl}/ISteamUser/GetPlayerSummaries/v0002/?key=$apiKey&steamids=$steamId64',
      );
      final res = await httpClient.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final players =
            (data['response'] as Map<String, dynamic>?)?['players'] as List<dynamic>?;
        if (players != null && players.isNotEmpty) {
          return SteamPlayerProfile.fromMap(players.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error fetching Steam player profile: $e');
    }
    return null;
  }

  /// Fetches the user's owned games and playtime
  Future<List<GameModel>> fetchOwnedGames(
    String steamId64, {
    required String apiKey,
    http.Client? client,
  }) async {
    if (apiKey.trim().isEmpty || steamId64.trim().isEmpty) return [];

    try {
      final httpClient = client ?? http.Client();
      final url = Uri.parse(
        '${SteamConfig.apiBaseUrl}/IPlayerService/GetOwnedGames/v0001/?key=$apiKey&steamid=$steamId64&format=json&include_appinfo=1&include_played_free_games=1',
      );
      final res = await httpClient.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final responseObj = data['response'] as Map<String, dynamic>?;
        final gamesJson = responseObj?['games'] as List<dynamic>?;

        if (gamesJson == null || gamesJson.isEmpty) {
          return [];
        }

        return gamesJson.map((g) {
          final map = g as Map<String, dynamic>;
          final appId = (map['appid'] as num).toInt();
          final title = (map['name'] as String?)?.trim() ?? 'Steam Game';
          final minutesForever = (map['playtime_forever'] as num?)?.toInt() ?? 0;
          final minutes2Weeks = (map['playtime_2weeks'] as num?)?.toInt() ?? 0;
          final hours = (minutesForever / 60.0).round();
          final recentHours = (minutes2Weeks / 60.0);

          return GameModel(
            id: 'steam-$appId',
            title: title,
            genre: 'Steam Library',
            emoji: '🎮',
            bannerGradientStart: '#1E293B',
            bannerGradientEnd: '#0F172A',
            isSteamGame: true,
            steamAppId: appId,
            playtimeHours: hours,
            recentPlaytimeHours: recentHours,
            imageUrl: '${SteamConfig.cdnArtworkBase}/$appId/header.jpg',
            squadOwnersCount: 1,
            squadTotalCount: 1,
            isInstalled: false,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching owned Steam games: $e');
    }
    return [];
  }

  /// Comprehensive sync operation: Resolves Steam ID, fetches profile, and extracts owned games.
  Future<SteamSyncResult> syncSteamAccount({
    required String input,
    required String apiKey,
    http.Client? client,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return SteamSyncResult.failure(
        'Steam Web API Key is missing. Paste your key in Settings or add to steam_config.dart.',
      );
    }

    final steamId = await resolveSteamId(input, apiKey: key, client: client);
    if (steamId == null) {
      return SteamSyncResult.failure(
        'Could not resolve Steam ID. Please check your Friend Code, SteamID64, or vanity profile URL.',
      );
    }

    final profile = await fetchPlayerProfile(steamId, apiKey: key, client: client);
    if (profile == null) {
      return SteamSyncResult.failure(
        'Steam account not found or Steam Web API key is invalid.',
      );
    }

    final games = await fetchOwnedGames(steamId, apiKey: key, client: client);
    if (games.isEmpty) {
      return SteamSyncResult(
        isSuccess: true,
        profile: profile,
        games: const [],
        errorMessage:
            'No games found. If you own games, make sure your Steam profile "Game Details" privacy is set to Public.',
      );
    }

    return SteamSyncResult.success(
      profile: profile,
      games: games,
    );
  }
}
