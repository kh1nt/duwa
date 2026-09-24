import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duwa/models/game_model.dart';
import 'package:duwa/models/game_night_model.dart';
import 'package:duwa/models/group_model.dart';
import 'package:duwa/services/notification_service.dart';
import 'package:duwa/services/preferences_service.dart';
import 'package:duwa/viewmodels/game_night_viewmodel.dart';
import 'package:duwa/viewmodels/profile_viewmodel.dart';
import 'package:duwa/viewmodels/theme_viewmodel.dart';
import 'package:duwa/views/profile/profile_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService().init();
    await NotificationService().init();
  });

  group('Notification Preferences & Service Logic', () {
    test('PreferencesService defaults and persists notification settings', () async {
      final prefs = PreferencesService();

      // Defaults to true
      expect(prefs.getPushNotificationsEnabled(), isTrue);
      expect(prefs.getReminder2HoursEnabled(), isTrue);
      expect(prefs.getReminder15MinsEnabled(), isTrue);
      expect(prefs.getVotingReminderEnabled(), isTrue);

      // Modify values
      await prefs.setPushNotificationsEnabled(false);
      await prefs.setReminder2HoursEnabled(false);
      await prefs.setReminder15MinsEnabled(false);
      await prefs.setVotingReminderEnabled(false);

      expect(prefs.getPushNotificationsEnabled(), isFalse);
      expect(prefs.getReminder2HoursEnabled(), isFalse);
      expect(prefs.getReminder15MinsEnabled(), isFalse);
      expect(prefs.getVotingReminderEnabled(), isFalse);

      // Re-enable
      await prefs.setPushNotificationsEnabled(true);
      expect(prefs.getPushNotificationsEnabled(), isTrue);
    });

    test('NotificationService generates deterministic non-negative notification IDs', () {
      final id1 = NotificationService.notificationId('session-abc', 120);
      final id2 = NotificationService.notificationId('session-abc', 15);
      final id3 = NotificationService.notificationId('session-abc', 120);
      final id4 = NotificationService.notificationId('session-xyz', 120);

      // Same session + offset yields identical ID
      expect(id1, equals(id3));
      // Different offsets yield different IDs
      expect(id1, isNot(equals(id2)));
      // Different sessions yield different IDs
      expect(id1, isNot(equals(id4)));
      // IDs must be non-negative 31-bit integers for native platforms
      expect(id1, greaterThanOrEqualTo(0));
      expect(id2, greaterThanOrEqualTo(0));
    });

    test('NotificationService schedule and cancel handlers run safely without exception', () async {
      final service = NotificationService();
      expect(service.isInitialized, isTrue);

      const dummyGroup = GamerGroupModel(
        id: 'g1',
        name: 'Friday Squad',
        tagline: 'Casual gaming squad',
        iconEmoji: '🎮',
        members: [
          PlayerModel(
            id: 'u1',
            name: 'Player',
            username: 'player_one',
            avatarInitials: 'P1',
            avatarColorIndex: 0,
            rsvp: RSVPStatus.going,
          ),
        ],
        squadCode: 'SQ-FR12',
        createdBy: 'u1',
      );

      final upcomingSession = GameNightModel(
        id: 'gn-test-1',
        title: 'Friday Valorant LAN',
        group: dummyGroup,
        organizerName: 'Player',
        scheduledDateTime: DateTime.now().add(const Duration(hours: 3)),
        formattedDate: 'Friday, Sep 26',
        formattedTime: '8:00 PM',
        status: GameNightStatus.ready,
        selectedGame: const GameModel(
          id: 'val-1',
          title: 'Valorant',
          genre: 'Tactical Shooter',
          emoji: '🎯',
          bannerGradientStart: '#FF5E1E',
          bannerGradientEnd: '#141722',
        ),
        players: [
          const PlayerModel(
            id: 'u1',
            name: 'Player',
            username: 'player_one',
            avatarInitials: 'P1',
            avatarColorIndex: 0,
            rsvp: RSVPStatus.going,
          ),
        ],
      );

      // Should schedule without exception
      await service.scheduleSessionReminders(
        session: upcomingSession,
        isUserAttending: true,
      );

      // Should cancel without exception
      await service.cancelSessionReminders(upcomingSession.id);
      await service.cancelAll();
    });
  });

  group('ProfileView Notification Settings Sheet', () {
    testWidgets('Renders Notification Reminders setting tile and opens bottom sheet',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final profileVm = ProfileViewModel();
      profileVm.setProfile(name: 'SquadLeader', uid: 'u1');
      final themeVm = ThemeViewModel();
      final gameNightVm = GameNightViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileView(
              profileVm: profileVm,
              themeVm: themeVm,
              gameNightVm: gameNightVm,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to APP SETTINGS
      final tileFinder = find.text('Notification Reminders');
      await tester.scrollUntilVisible(
        tileFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tileFinder, findsOneWidget);

      // Tap on Notification Reminders
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      // Modal bottom sheet should appear with options
      expect(find.text('Push Reminders'), findsOneWidget);
      expect(find.text('2 Hours Before Session'), findsOneWidget);
      expect(find.text('15 Minutes Countdown'), findsOneWidget);
      expect(find.text('Game Voting Ballots'), findsOneWidget);
      expect(find.text('Send Test Push Notification'), findsOneWidget);

      // Tap Test Push Notification button
      final testBtn = find.text('Send Test Push Notification');
      expect(testBtn, findsOneWidget);
      await tester.tap(testBtn);
      await tester.pump();
    });
  });
}
