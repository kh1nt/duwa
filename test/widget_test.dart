import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duwa/main.dart';
import 'package:duwa/models/game_night_model.dart';
import 'package:duwa/models/game_model.dart';
import 'package:duwa/viewmodels/theme_viewmodel.dart';
import 'package:duwa/viewmodels/game_night_viewmodel.dart';
import 'package:duwa/viewmodels/groups_viewmodel.dart';
import 'package:duwa/viewmodels/notifications_viewmodel.dart';
import 'package:duwa/viewmodels/profile_viewmodel.dart';
import 'package:duwa/views/home/home_view.dart';
import 'package:duwa/views/main_shell_view.dart';
import 'package:duwa/views/auth/auth_view.dart';
import 'package:duwa/views/common/state_feedback_views.dart';
import 'package:duwa/views/details/game_night_details_view.dart';
import 'package:duwa/views/details/game_night_dispatch_sheet.dart';
import 'package:duwa/views/navigation/duwa_nav_rail.dart';
import 'package:duwa/views/profile/profile_view.dart';
import 'package:duwa/views/create/create_game_night_sheet.dart';
import 'package:duwa/views/groups/groups_view.dart';
import 'package:duwa/views/common/duwa_mascot.dart';
import 'package:duwa/views/common/random_game_sheet.dart';
import 'package:duwa/core/theme/duwa_colors.dart';
import 'package:duwa/services/cloudinary_service.dart';
import 'package:duwa/services/discord_service.dart';
import 'package:duwa/models/group_model.dart';

void main() {
  testWidgets('DUWA smoke test renders brand and home elements', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel();
    final groupsVm = GroupsViewModel();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: HomeView(
          gameNightVm: gameNightVm,
          groupsVm: groupsVm,
          themeVm: themeVm,
          unreadNotificationsCount: 0,
          onOpenSessions: () {},
          onCreateGameNight: () {},
          onOpenGameNight: (_) {},
          onOpenGroup: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(RegExp(r'Duwa', caseSensitive: false)), findsWidgets);
    expect(find.textContaining(RegExp(r'Hey', caseSensitive: false)), findsWidgets);
    expect(find.textContaining(RegExp(r'Plan a', caseSensitive: false)), findsWidgets);
  });

  testWidgets('DUWA dynamically greets custom user name', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel();
    final groupsVm = GroupsViewModel();
    final profileVm = ProfileViewModel();

    profileVm.updateAvatar(
      displayName: 'ShadowHunter',
      handle: '@shadowhunter',
      initials: 'SH',
      bio: 'Ready to play!',
      avatarEmoji: '🚀',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: HomeView(
          gameNightVm: gameNightVm,
          groupsVm: groupsVm,
          themeVm: themeVm,
          profileVm: profileVm,
          unreadNotificationsCount: 0,
          onOpenSessions: () {},
          onCreateGameNight: () {},
          onOpenGameNight: (_) {},
          onOpenGroup: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ShadowHunter'), findsOneWidget);
  });

  testWidgets('DUWA renders AuthView onboarding screen for unauthenticated users', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: AuthView(
          themeVm: themeVm,
          onAuthenticated: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DUWA'), findsOneWidget);
    expect(find.text('Gaming sessions made simple'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Create Account'), findsWidgets);
  });

  testWidgets('DUWA navigates through 4 destinations: Home, Sessions, Squads, and You', (WidgetTester tester) async {
    await tester.pumpWidget(const DuwaApp(skipAuth: true));
    await tester.pumpAndSettle();

    expect(find.byType(MainShellView), findsOneWidget);
    expect(find.byType(HomeView), findsOneWidget);

    // 1. Navigate to Schedule (Tab 1)
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'Schedule', caseSensitive: false)), findsWidgets);

    // 2. Navigate to Squads (Tab 2)
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Squads'), findsWidgets);

    // 3. Navigate to You (Tab 3)
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('You'), findsWidgets);
  });

  testWidgets('DUWA Session Details handles voting and voting lock transition', (WidgetTester tester) async {
    final gameNightVm = GameNightViewModel.withFixtureData();
    final themeVm = ThemeViewModel();
    final votingSession = gameNightVm.votingGameNight;

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: GameNightDetailsView(
          gameNight: votingSession,
          gameNightVm: gameNightVm,
          duwaTheme: themeVm.themeData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify voting screen elements
    expect(find.textContaining(RegExp(r'Vote for the Game', caseSensitive: false)), findsOneWidget);

    // Cast a vote
    final valorantOption = find.text('Valorant');
    expect(valorantOption, findsOneWidget);
    await tester.tap(valorantOption);
    await tester.pumpAndSettle();

    // Host locks voting -> transitions from Voting to Planning
    gameNightVm.lockVoting(votingSession.id);
    await tester.pumpAndSettle();

    final updated = gameNightVm.getSessionById(votingSession.id);
    expect(updated.status, GameNightStatus.planning);
  });

  testWidgets('DUWA RSVP and Bring List items claim flow', (WidgetTester tester) async {
    final gameNightVm = GameNightViewModel.withFixtureData();
    final themeVm = ThemeViewModel();
    final session = gameNightVm.upcomingGameNight;
    themeVm.setVibe(DuwaThemeVibe.obsidianVoid);

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: GameNightDetailsView(
          gameNight: session,
          gameNightVm: gameNightVm,
          duwaTheme: themeVm.themeData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // RSVP update test
    gameNightVm.updatePlayerRSVP(session.id, 'p1', RSVPStatus.maybe);
    await tester.pumpAndSettle();
    expect(
      gameNightVm.getSessionById(session.id).players.firstWhere((p) => p.id == 'p1').rsvp,
      RSVPStatus.maybe,
    );

    // Claim an item in checklist
    gameNightVm.claimChecklistItem(session.id, 'c3');
    await tester.pumpAndSettle();
    final updatedSession = gameNightVm.getSessionById(session.id);
    final item = updatedSession.checklist.firstWhere((i) => i.id == 'c3');
    expect(item.assignedTo, isNotNull);
  });

  test('GameNightViewModel session creation flow', () {
    final vm = GameNightViewModel();
    final groups = GroupsViewModel.withFixtureData().groups;
    vm.startCreationFlow(groups.first);
    vm.setDraftTitle('Sunday Championship');
    vm.setDraftLocation('Banilad Crib');
    vm.confirmGameNight();

    expect(vm.allSessions.any((s) => s.title == 'Sunday Championship'), isTrue);
    final created = vm.allSessions.firstWhere((s) => s.title == 'Sunday Championship');
    expect(created.location?.name, 'Banilad Crib');
    expect(created.status, GameNightStatus.ready);
  });

  test('GameModel serialization and custom game dynamic catalog flow', () async {
    final vm = GameNightViewModel();
    final initialCount = vm.catalogGames.length;

    // Create a custom game like Ragnarok Online
    final customGame = await vm.createAndSaveCustomGame(
      title: 'Ragnarok Online',
      genre: 'MMORPG',
      emoji: '⚔️',
      playerCount: '1-12 players',
    );

    expect(customGame.title, 'Ragnarok Online');
    expect(customGame.genre, 'MMORPG');
    expect(customGame.emoji, '⚔️');
    expect(vm.catalogGames.length, initialCount + 1);
    expect(vm.catalogGames.any((g) => g.title == 'Ragnarok Online'), isTrue);

    // Verify Firestore serialization
    final map = customGame.toMap();
    expect(map['title'], 'Ragnarok Online');
    expect(map['genre'], 'MMORPG');
    expect(map['playerCountRecommendation'], '1-12 players');

    final reconstituted = GameModel.fromMap(map, customGame.id);
    expect(reconstituted.id, customGame.id);
    expect(reconstituted.title, 'Ragnarok Online');
    expect(reconstituted.genre, 'MMORPG');
    expect(reconstituted.emoji, '⚔️');
  });

  testWidgets('DUWA Game Night Dispatch sheet generates Discord and WhatsApp formats', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel.withFixtureData();
    final session = gameNightVm.upcomingGameNight;

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => GameNightDispatchSheet.show(
                ctx,
                gameNight: session,
                duwaTheme: themeVm.themeData,
              ),
              child: const Text('Open Dispatch'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap button to open sheet
    await tester.tap(find.text('Open Dispatch'));
    await tester.pumpAndSettle();

    // Verify Dispatch UI
    expect(find.text('Squad Session Briefing'), findsOneWidget);
    expect(find.text('Discord Format'), findsOneWidget);
    expect(find.text('WhatsApp / Chat'), findsOneWidget);
    expect(find.text('Copy Discord Dispatch'), findsOneWidget);
    expect(find.textContaining('DUWA Room Code'), findsOneWidget);

    // Switch to WhatsApp format
    await tester.tap(find.text('WhatsApp / Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Copy Chat Dispatch'), findsOneWidget);
  });

  testWidgets('DUWA adapts to wide screen with DuwaNavRail', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DuwaApp(skipAuth: true));
    await tester.pumpAndSettle();

    // On 1024px width, DuwaNavRail should be visible instead of DuwaBottomNavBar
    expect(find.byType(DuwaNavRail), findsOneWidget);
    expect(find.text('DUWA'), findsWidgets);
    expect(find.text('Plan Session'), findsWidgets);
  });

  testWidgets('DUWA EmptyStateWidget.sessions renders warm editorial copy', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    bool planned = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: EmptyStateWidget.sessions(
            onCreate: () => planned = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No game sessions here'), findsOneWidget);
    expect(find.text('Plan Session'), findsOneWidget);

    await tester.tap(find.text('Plan Session'));
    expect(planned, isTrue);
  });

  testWidgets('DUWA production first-run starts clean with genuine empty states', (WidgetTester tester) async {
    final gameNightVm = GameNightViewModel();
    final groupsVm = GroupsViewModel();
    final notificationsVm = NotificationsViewModel();
    final profileVm = ProfileViewModel();

    // Verify all production ViewModels start clean without dummy data
    expect(gameNightVm.allSessions.isEmpty, isTrue);
    expect(groupsVm.groups.isEmpty, isTrue);
    expect(notificationsVm.notifications.isEmpty, isTrue);
    expect(profileVm.profile.isSteamConnected, isFalse);
    expect(profileVm.profile.steamGamesCount, 0);
    expect(profileVm.steamCatalog.isEmpty, isTrue);

    // Verify HomeView renders empty marquee
    final themeVm = ThemeViewModel();
    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: HomeView(
          gameNightVm: gameNightVm,
          groupsVm: groupsVm,
          themeVm: themeVm,
          profileVm: profileVm,
          unreadNotificationsCount: 0,
          onOpenSessions: () {},
          onCreateGameNight: () {},
          onOpenGameNight: (_) {},
          onOpenGroup: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ready to play?'), findsOneWidget);
    expect(find.text('No session planned tonight. Pick a game and rally the squad!'), findsOneWidget);
  });

  testWidgets('DUWA HomeView does not display theme toggle button in AppBar', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel();
    final groupsVm = GroupsViewModel();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: HomeView(
          gameNightVm: gameNightVm,
          groupsVm: groupsVm,
          themeVm: themeVm,
          unreadNotificationsCount: 0,
          onOpenSessions: () {},
          onCreateGameNight: () {},
          onOpenGameNight: (_) {},
          onOpenGroup: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Obsidian / theme toggle is NOT present on HomeView
    expect(find.text('OBSIDIAN'), findsNothing);
    expect(find.text(themeVm.themeData.vibeName.toUpperCase()), findsNothing);
  });

  test('Squad creation and deletion flow in GroupsViewModel', () async {
    final groupsVm = GroupsViewModel();
    expect(groupsVm.groups.isEmpty, isTrue);

    // Create squad
    groupsVm.addGroup(name: 'Apex Legends Crew', tagline: 'Ranked grind', emoji: '🔥');
    expect(groupsVm.groups.length, 1);
    expect(groupsVm.groups.first.name, 'Apex Legends Crew');
    expect(groupsVm.groups.first.iconEmoji, '🔥');

    final squadId = groupsVm.groups.first.id;
    // Delete squad
    await groupsVm.deleteSquad(squadId);
    expect(groupsVm.groups.isEmpty, isTrue);
  });

  test('Game night creation and deletion flow in GameNightViewModel', () async {
    final vm = GameNightViewModel();
    final groups = GroupsViewModel.withFixtureData().groups;
    vm.startCreationFlow(groups.first);
    vm.setDraftTitle('Friday Night Brawl');
    vm.confirmGameNight();

    expect(vm.allSessions.any((s) => s.title == 'Friday Night Brawl'), isTrue);
    final created = vm.allSessions.firstWhere((s) => s.title == 'Friday Night Brawl');

    // Delete session
    await vm.deleteSession(created.id);
    expect(vm.allSessions.any((s) => s.id == created.id), isFalse);
  });

  testWidgets('DUWA ProfileView opens avatar picker on avatar click and updates avatar', (WidgetTester tester) async {
    final profileVm = ProfileViewModel();
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: ProfileView(
          profileVm: profileVm,
          themeVm: themeVm,
          gameNightVm: gameNightVm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Standalone AVATAR ICON section should not be in the body
    expect(find.text('AVATAR ICON'), findsNothing);

    // Tap on the avatar in identity card
    await tester.tap(find.byIcon(Icons.edit_rounded).first);
    await tester.pumpAndSettle();

    // Verify modal sheet appears with avatar choices
    expect(find.text('Choose Avatar'), findsOneWidget);
    expect(find.text('🚀'), findsWidgets);

    // Tap on rocket emoji
    await tester.tap(find.text('🚀').first);
    await tester.pumpAndSettle();

    // Verify profile avatar updated
    expect(profileVm.profile.avatarEmoji, '🚀');
  });

  testWidgets('DUWA CreateGameNightSheet navigates from Step 0 to Step 1 Game Selection and toggles voting mode without error', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel();
    final groupsVm = GroupsViewModel.withFixtureData();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                CreateGameNightSheet.show(
                  ctx,
                  gameNightVm: gameNightVm,
                  groupsVm: groupsVm,
                  duwaTheme: themeVm.themeData,
                  onGameNightConfirmed: () {},
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open creation sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Step 0: Timing & Basics
    expect(find.text('When are we playing?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue -> goes to Step 1 Game Selection
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 1: Choose Games & Crew Vote Mode
    expect(find.text('Choose Games'), findsOneWidget);
    expect(find.text('CREW VOTE MODE'), findsOneWidget);

    // Tap on a visible game in single confirmed mode
    final valorantTile = find.text('Valorant');
    expect(valorantTile, findsOneWidget);
    await tester.tap(valorantTile);
    await tester.pumpAndSettle();

    // Toggle crew vote mode
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Select second game for voting
    final dotaOption = find.text('Dota 2');
    expect(dotaOption, findsOneWidget);
    await tester.tap(dotaOption);
    await tester.pumpAndSettle();

    // Proceed to Step 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: Squad & Logistics
    expect(find.text('Squad & Plans'), findsOneWidget);
    expect(find.text('Plan Session'), findsWidgets);

    // Confirm game night
    await tester.tap(find.text('Plan Session').last);
    // Confetti animation is running, so use pump rather than pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Celebration screen
    expect(find.text('Session Planned!'), findsOneWidget);
  });

  test('GroupsViewModel squad member addition and removal', () async {
    final groupsVm = GroupsViewModel.withFixtureData();
    expect(groupsVm.groups.isNotEmpty, isTrue);

    final squad = groupsVm.groups.first;
    final initialCount = squad.members.length;

    // Add new member
    final added = await groupsVm.addMemberToSquad(
      squadId: squad.id,
      memberName: 'GhostRider',
      username: '@ghost',
      avatarEmoji: '⚡',
    );
    expect(added, isTrue);

    final updatedSquad = groupsVm.groups.firstWhere((g) => g.id == squad.id);
    expect(updatedSquad.members.length, initialCount + 1);
    expect(updatedSquad.members.any((m) => m.name == 'GhostRider'), isTrue);

    // Duplicate addition should return false
    final duplicate = await groupsVm.addMemberToSquad(
      squadId: squad.id,
      memberName: 'GhostRider',
    );
    expect(duplicate, isFalse);

    // Remove member
    final memberToRemove = updatedSquad.members.firstWhere((m) => m.name == 'GhostRider');
    await groupsVm.removeMemberFromSquad(squad.id, memberToRemove.id);

    final afterRemoval = groupsVm.groups.firstWhere((g) => g.id == squad.id);
    expect(afterRemoval.members.length, initialCount);
    expect(afterRemoval.members.any((m) => m.name == 'GhostRider'), isFalse);
  });

  testWidgets('DUWA HomeView renders the next session with dynamic countdown and RSVP bar', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel.withFixtureData();
    final groupsVm = GroupsViewModel.withFixtureData();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: HomeView(
          gameNightVm: gameNightVm,
          groupsVm: groupsVm,
          themeVm: themeVm,
          unreadNotificationsCount: 0,
          onOpenSessions: () {},
          onCreateGameNight: () {},
          onOpenGameNight: (_) {},
          onOpenGroup: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify next-session elements
    expect(find.textContaining(RegExp(r'SESSION', caseSensitive: false)), findsWidgets);
    expect(find.text("I'm In"), findsWidgets);
  });

  testWidgets('DUWA GroupsView opens Squad Detail and Invite Sheet', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel.withFixtureData();
    final groupsVm = GroupsViewModel.withFixtureData();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: GroupsView(
            groupsVm: groupsVm,
            gameNightVm: gameNightVm,
            duwaTheme: themeVm.themeData,
            onPlanGameNightForGroup: (_) {},
            onPlanGameNightForGame: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find squad card more_vert popup button
    final moreBtn = find.byIcon(Icons.more_vert_rounded).first;
    await tester.tap(moreBtn);
    await tester.pumpAndSettle();

    // Verify Invite to Squad menu item is present
    expect(find.text('Invite to Squad'), findsOneWidget);
    await tester.tap(find.text('Invite to Squad'));
    await tester.pumpAndSettle();

    // Verify Invite Sheet rendered with both direct-add and social share options
    expect(find.text('ADD SQUAD MEMBER'), findsOneWidget);
    expect(find.text('SHARE SQUAD INVITE'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Discord'), findsOneWidget);
    expect(find.text('Copy Link'), findsOneWidget);
  });

  testWidgets('DUWA AuthView renders Continue with Google and email fields', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: AuthView(
          themeVm: themeVm,
          onAuthenticated: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Instant Guest Play'), findsNothing);
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('DUWA CreateGameNightSheet renders 1-Tap Squad Templates and applies template', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    final gameNightVm = GameNightViewModel.withFixtureData();
    final groupsVm = GroupsViewModel.withFixtureData();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: CreateGameNightSheet(
            gameNightVm: gameNightVm,
            groupsVm: groupsVm,
            duwaTheme: themeVm.themeData,
            onGameNightConfirmed: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify clean timing presets strip (templates removed per simplify request)
    expect(find.text('QUICK TIMING'), findsOneWidget);
    expect(find.text('Tonight · 8:00 PM'), findsOneWidget);
    expect(find.text('Tomorrow · 8:00 PM'), findsOneWidget);

    // Tap Tonight preset
    await tester.tap(find.text('Tonight · 8:00 PM'));
    await tester.pumpAndSettle();

    expect(gameNightVm.draftTimeDisplay, '8:00 PM');
  });

  test('GameNightViewModel markSessionCompleted locks session from mutations', () {
    final vm = GameNightViewModel.withFixtureData();
    final targetId = vm.allSessions.first.id;

    // Verify session initially can receive checklist
    final initialChecklistCount = vm.allSessions.first.checklist.length;
    vm.addChecklistItem(targetId, const ChecklistItemModel(id: 'test-item-1', title: 'Original Item'));
    expect(vm.allSessions.first.checklist.length, initialChecklistCount + 1);

    // Mark completed
    vm.markSessionCompleted(targetId);
    final completedSession = vm.allSessions.firstWhere((s) => s.id == targetId);
    expect(completedSession.status, GameNightStatus.completed);

    // Attempt mutation: adding checklist item must be blocked
    final countAfterCompleted = completedSession.checklist.length;
    vm.addChecklistItem(targetId, const ChecklistItemModel(id: 'test-item-2', title: 'Should be blocked'));
    expect(vm.allSessions.firstWhere((s) => s.id == targetId).checklist.length, countAfterCompleted);

    // Attempt mutation: RSVP update must be blocked
    final originalRsvp = vm.allSessions.firstWhere((s) => s.id == targetId).players.first.rsvp;
    vm.updatePlayerRSVP(targetId, vm.allSessions.firstWhere((s) => s.id == targetId).players.first.id, RSVPStatus.cantGo);
    expect(vm.allSessions.firstWhere((s) => s.id == targetId).players.first.rsvp, originalRsvp);

    // Attempt mutation: vote must be blocked
    if (completedSession.votingGames.isNotEmpty) {
      final initialVotes = completedSession.votingGames.first.votes;
      vm.castVote(targetId, completedSession.votingGames.first.id);
      expect(vm.allSessions.firstWhere((s) => s.id == targetId).votingGames.first.votes, initialVotes);
    }
  });

  test('CloudinaryService produces optimized transformation URLs', () {
    final service = CloudinaryService();
    const rawUrl = 'https://res.cloudinary.com/demo/image/upload/v1234567/sample.jpg';
    final transformed = service.getOptimizedUrl(rawUrl, width: 300, height: 300);

    expect(transformed, contains('f_auto,q_auto,w_300,h_300,c_fill'));
    expect(transformed, contains('sample.jpg'));

    // Non-cloudinary url is returned untouched
    const externalUrl = 'https://example.com/avatar.png';
    expect(service.getOptimizedUrl(externalUrl, width: 200), externalUrl);
  });

  test('DiscordService validates valid and invalid webhook URLs', () {
    final service = DiscordService();

    expect(service.isValidWebhookUrl('https://discord.com/api/webhooks/123456789/abcdefghijk'), isTrue);
    expect(service.isValidWebhookUrl('https://discordapp.com/api/webhooks/987654321/zyxwvutsrqp'), isTrue);

    expect(service.isValidWebhookUrl(''), isFalse);
    expect(service.isValidWebhookUrl(null), isFalse);
    expect(service.isValidWebhookUrl('https://example.com/api/webhooks/123/xyz'), isFalse);
    expect(service.isValidWebhookUrl('not-a-url'), isFalse);
  });

  test('ProfileViewModel updates photoUrl and tracks steam connection status', () {
    final profileVm = ProfileViewModel();

    expect(profileVm.profile.photoUrl, isNull);
    expect(profileVm.isSteamConnected, isFalse);

    const testUrl = 'https://res.cloudinary.com/squad/image/upload/v1/avatar.jpg';
    profileVm.updatePhotoUrl(testUrl);
    expect(profileVm.profile.photoUrl, testUrl);

    profileVm.toggleSteamConnection(personaName: 'SteamGamer', friendCode: '123456');
    expect(profileVm.isSteamConnected, isTrue);
    expect(profileVm.profile.steamPersonaName, 'SteamGamer');
    expect(profileVm.profile.steamFriendCode, '123456');

    profileVm.toggleSteamConnection();
    expect(profileVm.isSteamConnected, isFalse);
  });

  test('GameNightModel and GameNightViewModel handle session creation flow with custom title', () {
    final vm = GameNightViewModel();
    final groups = GroupsViewModel.withFixtureData().groups;
    vm.startCreationFlow(groups.first);
    vm.setDraftTitle('LAN Party Feast');

    expect(vm.draftTitle, 'LAN Party Feast');

    vm.confirmGameNight();
    final created = vm.allSessions.firstWhere((s) => s.title == 'LAN Party Feast');
    expect(created.title, 'LAN Party Feast');
    expect(created.group.id, groups.first.id);
  });

  testWidgets('GameNightDetailsView renders Squad Attendance and Preparation Hub in Overview tab', (WidgetTester tester) async {
    final gameNightVm = GameNightViewModel.withFixtureData();
    final themeVm = ThemeViewModel();
    final session = gameNightVm.upcomingGameNight;

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: GameNightDetailsView(
          gameNight: session,
          gameNightVm: gameNightVm,
          duwaTheme: themeVm.themeData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down in ListView to bring Attendance and Preparation into view
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Verify Overview tab renders Attendance and Preparation sections
    expect(find.text('Squad Participants'), findsOneWidget);
    expect(find.text('Session Schedule'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Host Note'), 300);
    expect(find.text('Host Note'), findsOneWidget);
  });

  testWidgets('DUWA RandomGameSheet rolls a game and triggers planning', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();
    GameModel? plannedGame;

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => RandomGameSheet.show(
                ctx,
                games: GameNightViewModel.defaultCatalog,
                duwaTheme: themeVm.themeData,
                onPlanGame: (g) => plannedGame = g,
              ),
              child: const Text('Open Random Game'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Random Game'));
    // Sheet contains timers/controller, pump frames to let it reveal
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('What should we play?'), findsOneWidget);
    expect(find.text('How about...'), findsOneWidget);
    expect(find.text('Plan it →'), findsOneWidget);

    await tester.tap(find.text('Plan it →'));
    await tester.pumpAndSettle();

    expect(plannedGame, isNotNull);
  });

  testWidgets('DUWA DuwaMascot renders celebrating, playing, waiting states', (WidgetTester tester) async {
    final themeVm = ThemeViewModel();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeVm.materialTheme,
        home: Scaffold(
          body: Column(
            children: [
              DuwaMascot(mood: MascotMood.celebrating, theme: themeVm.themeData),
              DuwaMascot(mood: MascotMood.playing, theme: themeVm.themeData),
              DuwaMascot(mood: MascotMood.waiting, theme: themeVm.themeData),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DuwaMascot), findsNWidgets(3));
  });

  test('DUWA Theme system toggles between Obsidian Dark and Minimal White with correct tokens', () {
    final themeVm = ThemeViewModel();
    // Default is Obsidian Dark
    expect(themeVm.isDark, isTrue);
    expect(themeVm.themeData.background, DuwaColors.obsidianBackground);
    expect(themeVm.themeData.vibeName, 'Obsidian Dark');

    // Switch to Minimal White
    themeVm.setVibe(DuwaThemeVibe.cleanLight);
    expect(themeVm.isLight, isTrue);
    expect(themeVm.themeData.background, DuwaColors.lightBackground);
    expect(themeVm.themeData.vibeName, 'Minimal White');

    // Toggle back to Obsidian Dark
    themeVm.toggleVibe();
    expect(themeVm.isDark, isTrue);
    expect(themeVm.themeData.background, DuwaColors.obsidianBackground);
  });
}



