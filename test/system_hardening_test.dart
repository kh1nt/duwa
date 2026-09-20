import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duwa/core/theme/duwa_colors.dart';
import 'package:duwa/models/game_model.dart';
import 'package:duwa/models/game_night_model.dart';
import 'package:duwa/models/group_model.dart';
import 'package:duwa/models/notification_model.dart';
import 'package:duwa/models/user_profile_model.dart';
import 'package:duwa/services/firebase_service.dart';
import 'package:duwa/services/preferences_service.dart';
import 'package:duwa/viewmodels/notifications_viewmodel.dart';
import 'package:duwa/viewmodels/theme_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService().init();
  });

  group('System Hardening — PreferencesService & Theme Persistence', () {
    test('PreferencesService persists and retrieves theme vibe', () async {
      final prefs = PreferencesService();
      expect(prefs.getThemeVibe(), isNull);

      await prefs.setThemeVibe('cleanLight');
      expect(prefs.getThemeVibe(), equals('cleanLight'));

      await prefs.setThemeVibe('obsidianVoid');
      expect(prefs.getThemeVibe(), equals('obsidianVoid'));
    });

    test('ThemeViewModel initializes from saved theme and persists changes', () async {
      final prefs = PreferencesService();
      await prefs.setThemeVibe('cleanLight');

      final themeVm = ThemeViewModel();
      expect(themeVm.currentVibe, equals(DuwaThemeVibe.cleanLight));
      expect(themeVm.isLight, isTrue);

      themeVm.toggleVibe();
      expect(themeVm.currentVibe, equals(DuwaThemeVibe.obsidianVoid));
      expect(prefs.getThemeVibe(), equals('obsidianVoid'));
    });

    test('PreferencesService caches and restores user profile offline', () async {
      final prefs = PreferencesService();
      expect(prefs.getCachedUserProfile(), isNull);

      const profile = UserProfileModel(
        id: 'user-xyz',
        displayName: 'GhostRider',
        handle: '@ghost',
        bio: 'Sniping from afar',
        avatarInitials: 'GR',
        avatarEmoji: '⚡',
      );

      await prefs.setCachedUserProfile(profile.toMap());

      final cached = prefs.getCachedUserProfile();
      expect(cached, isNotNull);
      expect(cached!['displayName'], equals('GhostRider'));
      expect(cached['handle'], equals('@ghost'));

      final restored = UserProfileModel.fromMap(cached);
      expect(restored.displayName, equals('GhostRider'));
      expect(restored.avatarEmoji, equals('⚡'));
    });

    test('PreferencesService tracks read notifications and marks as read', () async {
      final prefs = PreferencesService();
      expect(prefs.getReadNotificationIds(), isEmpty);

      await prefs.markNotificationRead('notif_1');
      await prefs.markNotificationRead('notif_2');

      final readIds = prefs.getReadNotificationIds();
      expect(readIds.contains('notif_1'), isTrue);
      expect(readIds.contains('notif_2'), isTrue);
      expect(readIds.contains('notif_3'), isFalse);
    });
  });

  group('System Hardening — Notifications Engine & Active Sessions Sync', () {
    test('NotificationsViewModel syncs with upcoming sessions and ballots', () {
      final notifVm = NotificationsViewModel();
      expect(notifVm.notifications, isEmpty);

      const testPlayer = PlayerModel(
        id: 'p1',
        name: 'Alex (You)',
        username: 'alex',
        avatarInitials: 'AL',
        avatarColorIndex: 0,
        rsvp: RSVPStatus.going,
      );

      final votingSession = GameNightModel(
        id: 'session-vote-1',
        title: 'Friday Squad Battle',
        group: const GamerGroupModel(
          id: 'g1',
          name: 'The Boys',
          tagline: 'Always game ready',
          iconEmoji: '🔥',
          members: [testPlayer],
        ),
        status: GameNightStatus.voting,
        formattedDate: 'Fri, Oct 24',
        formattedTime: '8:00 PM',
        votingGames: const [
          GameModel(
            id: 'g1',
            title: 'Valorant',
            genre: 'Shooter',
            emoji: '🎯',
            bannerGradientStart: '#FF4655',
            bannerGradientEnd: '#0F1923',
          ),
          GameModel(
            id: 'g2',
            title: 'Apex Legends',
            genre: 'BR',
            emoji: '🏆',
            bannerGradientStart: '#DA292A',
            bannerGradientEnd: '#1F1F1F',
          ),
        ],
        players: const [testPlayer],
      );

      final scheduledSession = GameNightModel(
        id: 'session-ready-2',
        title: 'Saturday LAN Party',
        group: const GamerGroupModel(
          id: 'g2',
          name: 'Tabletop Crew',
          tagline: 'Roll for initiative',
          iconEmoji: '🎲',
          members: [testPlayer],
        ),
        status: GameNightStatus.ready,
        scheduledDateTime: DateTime.now().add(const Duration(hours: 3)),
        formattedDate: 'Tomorrow',
        formattedTime: '7:00 PM',
        players: const [testPlayer],
      );

      notifVm.syncWithSessions(
        sessions: [votingSession, scheduledSession],
        currentUserId: 'p1',
        currentUserName: 'Alex',
      );

      expect(notifVm.notifications.length, greaterThanOrEqualTo(2));
      final voteNotif = notifVm.notifications.firstWhere(
        (n) => n.category == NotificationCategory.vote,
      );
      expect(voteNotif.title, contains('Game Ballot'));

      final reminderNotif = notifVm.notifications.firstWhere(
        (n) => n.category == NotificationCategory.reminder,
      );
      expect(reminderNotif.title, contains('Saturday LAN Party'));
    });

    test('NotificationsViewModel markAllAsRead marks items and persists locally', () {
      final notifVm = NotificationsViewModel.withFixtureData();
      expect(notifVm.unreadCount, greaterThan(0));

      notifVm.markAllAsRead();
      expect(notifVm.unreadCount, equals(0));

      final readIds = PreferencesService().getReadNotificationIds();
      expect(readIds.contains('n1'), isTrue);
      expect(readIds.contains('n2'), isTrue);
    });
  });

  group('System Hardening — Firestore Transaction Handlers', () {
    test('castVote and updatePlayerRsvp safely handle test/offline environment', () async {
      final service = FirebaseService();

      // Calling without active Firebase app should safely return false without throwing uncaught error
      final voteSuccess = await service.castVote(
        gameNightId: 'fake-id',
        gameIndex: 0,
      );
      expect(voteSuccess, isFalse);

      final rsvpSuccess = await service.updatePlayerRsvp(
        gameNightId: 'fake-id',
        playerName: 'Gamer',
        rsvp: 'going',
      );
      expect(rsvpSuccess, isFalse);
    });
  });
}
