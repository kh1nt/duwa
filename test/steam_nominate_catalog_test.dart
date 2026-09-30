import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duwa/models/game_model.dart';
import 'package:duwa/models/user_profile_model.dart';
import 'package:duwa/services/preferences_service.dart';
import 'package:duwa/viewmodels/game_night_viewmodel.dart';
import 'package:duwa/viewmodels/groups_viewmodel.dart';
import 'package:duwa/viewmodels/profile_viewmodel.dart';
import 'package:duwa/viewmodels/theme_viewmodel.dart';
import 'package:duwa/views/profile/steam_integration_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService().init();
  });

  const testSteamGame = GameModel(
    id: 'steam-730',
    title: 'Counter-Strike 2',
    genre: 'Tactical Shooter · Valve',
    emoji: '🎯',
    bannerGradientStart: '#E58E26',
    bannerGradientEnd: '#F6B93B',
    isSteamGame: true,
    steamAppId: 730,
    imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg',
  );

  const testSteamGame2 = GameModel(
    id: 'steam-548430',
    title: 'Deep Rock Galactic',
    genre: 'Co-op Mining Shooter · Ghost Ship Games',
    emoji: '⛏️',
    bannerGradientStart: '#F59E0B',
    bannerGradientEnd: '#78350F',
    isSteamGame: true,
    steamAppId: 548430,
    imageUrl: 'https://cdn.cloudflare.steamstatic.com/steam/apps/548430/header.jpg',
  );

  group('Steam to Games Catalog & Nomination Unit Tests', () {
    test('addGameToCatalog adds Steam game to catalogGames and marks isSteamGame', () async {
      final vm = GameNightViewModel();
      final initialCount = vm.catalogGames.length;

      expect(vm.isGameInCatalog(testSteamGame), isFalse);

      final added = await vm.addGameToCatalog(testSteamGame);

      expect(vm.catalogGames.length, initialCount + 1);
      expect(vm.isGameInCatalog(testSteamGame), isTrue);
      expect(added.title, 'Counter-Strike 2');
      expect(added.isSteamGame, isTrue);
      expect(added.steamAppId, 730);

      // Calling again should return existing without duplicates
      final reAdded = await vm.addGameToCatalog(testSteamGame);
      expect(vm.catalogGames.length, initialCount + 1);
      expect(reAdded.id, added.id);
    });

    test('nominateGameForVoting adds to catalog even when no voting session exists', () async {
      final vm = GameNightViewModel();
      expect(vm.isGameInCatalog(testSteamGame2), isFalse);

      final nominated = await vm.nominateGameForVoting(testSteamGame2);

      // No active voting session -> returns false for ballot nomination
      expect(nominated, isFalse);
      // But game MUST be added to the games catalog!
      expect(vm.isGameInCatalog(testSteamGame2), isTrue);
      expect(vm.catalogGames.any((g) => g.title == 'Deep Rock Galactic'), isTrue);
    });

    test('nominateGameForVoting adds to both catalog and active session ballot', () async {
      final vm = GameNightViewModel();
      const user = UserProfileModel(
        id: 'test-user-123',
        displayName: 'GhostSquad',
        handle: '@ghostsquad',
        bio: 'Ready to play',
        avatarInitials: 'GS',
      );
      vm.syncCurrentUser(user);

      // Create a group and start voting session (selecting 2 games activates voting mode)
      final groups = GroupsViewModel.withFixtureData().groups;
      vm.startCreationFlow(groups.first);
      vm.setDraftTitle('Friday Squad Showdown');
      vm.toggleDraftGame(vm.catalogGames[1]);
      vm.confirmGameNight();

      expect(vm.hasActiveVotingSession, isTrue);
      expect(vm.isGameNominatedInActiveSession(testSteamGame), isFalse);

      // Nominate Steam game
      final success = await vm.nominateGameForVoting(testSteamGame);
      expect(success, isTrue);

      // Verify in games catalog
      expect(vm.isGameInCatalog(testSteamGame), isTrue);

      // Verify in active voting ballot
      expect(vm.isGameNominatedInActiveSession(testSteamGame), isTrue);

      final session = vm.allSessions.firstWhere((s) => s.title == 'Friday Squad Showdown');
      expect(session.votingGames.any((g) => g.title == 'Counter-Strike 2'), isTrue);
      final nominatedInSession = session.votingGames.firstWhere((g) => g.title == 'Counter-Strike 2');
      expect(nominatedInSession.votes, 1);
      expect(nominatedInSession.voterAvatars, contains('GS'));

      // Re-nominating should return false (already nominated)
      final duplicate = await vm.nominateGameForVoting(testSteamGame);
      expect(duplicate, isFalse);
    });

    test('addMultipleGamesToCatalog batch imports games without duplicates', () async {
      final vm = GameNightViewModel();
      final initialCount = vm.catalogGames.length;

      final count = await vm.addMultipleGamesToCatalog([testSteamGame, testSteamGame2]);
      expect(count, 2);
      expect(vm.catalogGames.length, initialCount + 2);
      expect(vm.isGameInCatalog(testSteamGame), isTrue);
      expect(vm.isGameInCatalog(testSteamGame2), isTrue);

      // Second batch with same games should add 0
      final countAgain = await vm.addMultipleGamesToCatalog([testSteamGame, testSteamGame2]);
      expect(countAgain, 0);
      expect(vm.catalogGames.length, initialCount + 2);
    });
  });

  group('SteamIntegrationView Widget Tests', () {
    testWidgets('Tapping Nominate button adds game to catalog and updates UI', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final themeVm = ThemeViewModel();
      final profileVm = ProfileViewModel();
      final gameNightVm = GameNightViewModel();
      final duwaTheme = themeVm.themeData;

      await tester.pumpWidget(
        MaterialApp(
          theme: themeVm.materialTheme,
          home: SteamIntegrationView(
            profileVm: profileVm,
            gameNightVm: gameNightVm,
            duwaTheme: duwaTheme,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find first Nominate button in the popular list (Counter-Strike 2)
      final nominateBtn = find.text('Nominate').first;
      expect(nominateBtn, findsOneWidget);

      await tester.tap(nominateBtn);
      await tester.pumpAndSettle();

      // Check feedback SnackBar
      expect(find.textContaining('Added "Counter-Strike 2" to Squad Games Catalog!'), findsOneWidget);

      // Verify the game is now in the viewmodel catalog
      expect(gameNightVm.catalogGames.any((g) => g.title == 'Counter-Strike 2'), isTrue);

      // The button text should now update to "In Catalog"
      expect(find.text('In Catalog'), findsAtLeastNWidgets(1));
    });

    testWidgets('Tapping Add All imports popular steam games into catalog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final themeVm = ThemeViewModel();
      final profileVm = ProfileViewModel();
      final gameNightVm = GameNightViewModel();
      final duwaTheme = themeVm.themeData;

      await tester.pumpWidget(
        MaterialApp(
          theme: themeVm.materialTheme,
          home: SteamIntegrationView(
            profileVm: profileVm,
            gameNightVm: gameNightVm,
            duwaTheme: duwaTheme,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final addAllBtn = find.text('Add All');
      expect(addAllBtn, findsOneWidget);

      await tester.tap(addAllBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Steam games to squad catalog!'), findsOneWidget);
      expect(gameNightVm.catalogGames.any((g) => g.title == 'Counter-Strike 2'), isTrue);
      expect(gameNightVm.catalogGames.any((g) => g.title == 'Phasmophobia'), isTrue);
    });
  });
}
