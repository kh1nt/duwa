import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:duwa/services/preferences_service.dart';
import 'package:duwa/services/steam_service.dart';
import 'package:duwa/viewmodels/profile_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SteamService Unit Tests', () {
    test('Converts 32-bit Friend Code to 64-bit SteamID correctly', () async {
      final service = SteamService();
      // Friend Code 87291044 -> 76561197960265728 + 87291044 = 76561198047556772
      final steamId = await service.resolveSteamId('87291044', apiKey: 'test_key');
      expect(steamId, '76561198047556772');
    });

    test('Preserves native 17-digit SteamID64', () async {
      final service = SteamService();
      const rawId64 = '76561198047556772';
      final steamId = await service.resolveSteamId(rawId64, apiKey: 'test_key');
      expect(steamId, rawId64);
    });

    test('Extracts SteamID64 from profile URL', () async {
      final service = SteamService();
      const profileUrl = 'https://steamcommunity.com/profiles/76561198047556772/';
      final steamId = await service.resolveSteamId(profileUrl, apiKey: 'test_key');
      expect(steamId, '76561198047556772');
    });

    test('Resolves custom vanity name using mock HTTP client', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('ResolveVanityURL')) {
          return http.Response(
            jsonEncode({
              'response': {
                'steamid': '76561198047556772',
                'success': 1,
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = SteamService();
      final steamId = await service.resolveSteamId(
        'custom_player_handle',
        apiKey: 'test_key',
        client: mockClient,
      );
      expect(steamId, '76561198047556772');
    });

    test('Fetches player profile and parses persona, avatar, and status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('GetPlayerSummaries')) {
          return http.Response(
            jsonEncode({
              'response': {
                'players': [
                  {
                    'steamid': '76561198047556772',
                    'personaname': 'GamerLegend',
                    'profileurl': 'https://steamcommunity.com/id/gamerlegend/',
                    'avatarfull': 'https://avatars.steamstatic.com/sample_full.jpg',
                    'personastate': 1,
                    'gameextrainfo': 'Counter-Strike 2',
                  }
                ]
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = SteamService();
      final profile = await service.fetchPlayerProfile(
        '76561198047556772',
        apiKey: 'test_key',
        client: mockClient,
      );

      expect(profile, isNotNull);
      expect(profile!.personaName, 'GamerLegend');
      expect(profile.avatarUrl, 'https://avatars.steamstatic.com/sample_full.jpg');
      expect(profile.isOnline, isTrue);
      expect(profile.statusText, 'Playing Counter-Strike 2');
    });

    test('Fetches owned games and formats playtime & official Steam CDN covers', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('GetOwnedGames')) {
          return http.Response(
            jsonEncode({
              'response': {
                'game_count': 2,
                'games': [
                  {
                    'appid': 730,
                    'name': 'Counter-Strike 2',
                    'playtime_forever': 3600, // 60 hours
                    'playtime_2weeks': 180, // 3 hours
                  },
                  {
                    'appid': 553850,
                    'name': 'Helldivers 2',
                    'playtime_forever': 1200, // 20 hours
                    'playtime_2weeks': 0,
                  }
                ]
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = SteamService();
      final games = await service.fetchOwnedGames(
        '76561198047556772',
        apiKey: 'test_key',
        client: mockClient,
      );

      expect(games.length, 2);
      expect(games[0].title, 'Counter-Strike 2');
      expect(games[0].playtimeHours, 60);
      expect(games[0].recentPlaytimeHours, 3.0);
      expect(
        games[0].displayCoverUrl,
        'https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg',
      );
      expect(games[1].title, 'Helldivers 2');
      expect(games[1].playtimeHours, 20);
    });

    test('Returns friendly error when Steam API Key is missing', () async {
      final service = SteamService();
      final result = await service.syncSteamAccount(input: '87291044', apiKey: '');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Steam Web API Key is missing'));
    });
  });

  group('ProfileViewModel Steam Integration', () {
    test('PreferencesService persists and retrieves Steam API key and input ID', () async {
      final prefs = PreferencesService();
      await prefs.setSteamApiKey('test_secret_api_key_123');
      await prefs.setSteamInputId('87291044');

      expect(prefs.getSteamApiKey(), 'test_secret_api_key_123');
      expect(prefs.getSteamInputId(), '87291044');

      await prefs.setSteamApiKey(null);
      await prefs.setSteamInputId(null);
      expect(prefs.getSteamApiKey(), isNull);
      expect(prefs.getSteamInputId(), isNull);
    });

    test('ProfileViewModel connects and filters real steam games', () async {
      final vm = ProfileViewModel();
      expect(vm.isSteamConnected, isFalse);

      vm.toggleSteamConnection(personaName: 'TestGamer', friendCode: '87291044');
      expect(vm.isSteamConnected, isTrue);
      expect(vm.profile.steamPersonaName, 'TestGamer');
      expect(vm.steamCatalog.isNotEmpty, isTrue);

      // Test search filter
      vm.setSteamSearchQuery('Left 4 Dead');
      expect(vm.steamCatalog.length, 1);
      expect(vm.steamCatalog.first.title, contains('Left 4 Dead'));

      vm.setSteamSearchQuery('');
      expect(vm.steamCatalog.length, greaterThan(1));

      // Disconnect
      vm.disconnectSteam();
      expect(vm.isSteamConnected, isFalse);
      expect(vm.steamCatalog.isEmpty, isTrue);
    });
  });
}
