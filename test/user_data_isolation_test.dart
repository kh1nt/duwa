import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duwa/models/game_night_model.dart';
import 'package:duwa/models/group_model.dart';
import 'package:duwa/models/user_profile_model.dart';
import 'package:duwa/services/preferences_service.dart';
import 'package:duwa/viewmodels/game_night_viewmodel.dart';
import 'package:duwa/viewmodels/groups_viewmodel.dart';
import 'package:duwa/viewmodels/profile_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PreferencesService User Session Isolation', () {
    test('clearUserSessionData removes profile and read notifications but retains theme', () async {
      final prefs = PreferencesService();
      await prefs.init();

      await prefs.setThemeVibe('obsidianVoid');
      await prefs.setCachedUserProfile({'displayName': 'CyberSamurai'}, 'user-123');
      await prefs.markNotificationRead('notif-1');

      expect(prefs.getThemeVibe(), 'obsidianVoid');
      expect(prefs.getCachedUserProfile('user-123')?['displayName'], 'CyberSamurai');
      expect(prefs.getReadNotificationIds().contains('notif-1'), isTrue);

      // Sign out / session wipe
      await prefs.clearUserSessionData();

      // Theme stays preserved for device aesthetics
      expect(prefs.getThemeVibe(), 'obsidianVoid');
      // User-specific data is completely wiped
      expect(prefs.getCachedUserProfile('user-123'), isNull);
      expect(prefs.getReadNotificationIds(), isEmpty);
    });

    test('getCachedUserProfile scopes by UID accurately', () async {
      final prefs = PreferencesService();
      await prefs.init();

      await prefs.setCachedUserProfile({'displayName': 'UserA'}, 'uid-A');
      await prefs.setCachedUserProfile({'displayName': 'UserB'}, 'uid-B');

      expect(prefs.getCachedUserProfile('uid-A')?['displayName'], 'UserA');
      expect(prefs.getCachedUserProfile('uid-B')?['displayName'], 'UserB');
      expect(prefs.getCachedUserProfile('uid-C'), isNull);
    });
  });

  group('ProfileViewModel Isolation & Reset', () {
    test('reset restores default profile template', () {
      final vm = ProfileViewModel();
      vm.setProfile(name: 'GamerGod', emoji: '🔥', uid: 'user-777');
      expect(vm.profile.displayName, 'GamerGod');
      expect(vm.profile.id, 'user-777');

      vm.reset();

      expect(vm.profile.displayName, 'Player');
      expect(vm.profile.id, 'user-default');
    });
  });

  group('GroupsViewModel Per-User Scoping & Reset', () {
    test('reset clears groups and resets selected group', () {
      final vm = GroupsViewModel.withFixtureData();
      expect(vm.groups, isNotEmpty);
      expect(vm.selectedGroup, isNotNull);

      vm.reset();

      expect(vm.groups, isEmpty);
      expect(vm.selectedGroup, isNull);
    });

    test('createSquad associates squad with user and allows member access', () {
      final vm = GroupsViewModel();
      vm.syncCurrentUser(const UserProfileModel(
        id: 'user-99',
        displayName: 'ShadowKnight',
        handle: '@shadow',
        bio: 'Ready',
        avatarInitials: 'SK',
        avatarEmoji: '⚔️',
        favoriteGames: [],
        gameNightsHosted: 0,
        gameNightsPlayed: 0,
        isSteamConnected: false,
        steamPersonaName: null,
        steamGamesCount: 0,
        steamFriendCode: null,
        steamLevel: 0,
        steamStatus: null,
        steamRecentHours: 0.0,
        lastSteamSync: null,
      ));

      vm.addGroup(name: 'Shadow Realm', emoji: '⚔️', tagline: 'Top Squad');
      expect(vm.groups.length, 1);
      expect(vm.groups.first.name, 'Shadow Realm');
      expect(vm.groups.first.members.any((m) => m.name.contains('ShadowKnight')), isTrue);
    });
  });

  group('GameNightViewModel Per-User Scoping & Reset', () {
    test('reset clears all sessions and draft state', () {
      final vm = GameNightViewModel.withFixtureData();
      expect(vm.allSessions, isNotEmpty);

      vm.reset();

      expect(vm.allSessions, isEmpty);
      expect(vm.upcomingSessions, isEmpty);
    });

    test('new user sees clean empty state until planning or joining a session', () {
      final vm = GameNightViewModel();
      vm.syncCurrentUser(const UserProfileModel(
        id: 'user-clean',
        displayName: 'NewComer',
        handle: '@newcomer',
        bio: '',
        avatarInitials: 'NC',
        avatarEmoji: '🎮',
        favoriteGames: [],
        gameNightsHosted: 0,
        gameNightsPlayed: 0,
        isSteamConnected: false,
        steamPersonaName: null,
        steamGamesCount: 0,
        steamFriendCode: null,
        steamLevel: 0,
        steamStatus: null,
        steamRecentHours: 0.0,
        lastSteamSync: null,
      ));

      expect(vm.allSessions, isEmpty);
      expect(vm.upcomingSessions, isEmpty);
      expect(vm.recentGameNights, isEmpty);
    });
  });

  group('Cross-User Data Isolation Verification', () {
    test('GameNightModel accurately reflects createdBy, playerUids, and host identity', () {
      final session = GameNightModel(
        id: 'gn-100',
        title: 'Valorant Showdown',
        group: const GamerGroupModel(
          id: 'g-1',
          name: 'Squad',
          tagline: 'Squad',
          iconEmoji: '🎮',
          members: [],
          createdBy: 'user-A',
          memberUids: ['user-A'],
        ),
        formattedDate: 'Tonight',
        formattedTime: '8:00 PM',
        status: GameNightStatus.ready,
        players: const [
          PlayerModel(
            id: 'user-A',
            name: 'Alice',
            username: '@alice',
            avatarInitials: 'A',
            avatarColorIndex: 0,
            rsvp: RSVPStatus.going,
          ),
        ],
        createdBy: 'user-A',
        playerUids: const ['user-A'],
        isHost: true,
      );

      expect(session.createdBy, 'user-A');
      expect(session.playerUids, contains('user-A'));
      expect(session.isHost, isTrue);

      // User B should not be host
      final sessionForB = session.copyWith(
        isHost: session.createdBy == 'user-B',
      );
      expect(sessionForB.isHost, isFalse);
    });

    test('GamerGroupModel tracks createdBy and memberUids accurately', () {
      const group = GamerGroupModel(
        id: 'group-alpha',
        name: 'Apex Predators',
        tagline: 'Grinding Ranked',
        iconEmoji: '🔥',
        members: [
          PlayerModel(
            id: 'user-1',
            name: 'Leader',
            username: '@leader',
            avatarInitials: 'L',
            avatarColorIndex: 0,
          ),
        ],
        createdBy: 'user-1',
        memberUids: ['user-1'],
      );

      expect(group.createdBy, 'user-1');
      expect(group.memberUids, contains('user-1'));
      expect(group.memberUids.contains('user-2'), isFalse);
    });
  });
}
