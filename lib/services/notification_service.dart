import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/game_night_model.dart';
import '../models/group_model.dart';
import 'preferences_service.dart';

/// Local and Scheduled Push Notification Service for DUWA.
/// Handles instant alerts, countdown reminders (2h, 15m), and voting ballots.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static const String _channelId = 'duwa_sessions';
  static const String _channelName = 'Squad Game Nights';
  static const String _channelDescription =
      'Alerts, countdowns, and reminders for DUWA squad game sessions';

  /// Notification Details for High Priority Game Night Reminders
  static const NotificationDetails _sessionNotificationDetails =
      NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Initialize local notification plugin and timezone database
  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked with payload: ${details.payload}');
        },
      );

      // Create Android Notification Channel
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlatform = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlatform != null) {
          await androidPlatform.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init note (desktop/test environment): $e');
      _initialized = true;
    }
  }

  /// Request runtime notification permissions on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlatform = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlatform != null) {
          final granted =
              await androidPlatform.requestNotificationsPermission();
          return granted ?? false;
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlatform = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosPlatform != null) {
          final granted = await iosPlatform.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Show an instant test notification (e.g. from Profile preferences)
  Future<bool> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.show(
        0,
        title,
        body,
        _sessionNotificationDetails,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('NotificationService show note: $e');
      return false;
    }
  }

  /// Trigger instant test notification verifying configuration
  Future<bool> showTestNotification() async {
    return showInstantNotification(
      title: '🎮 Squad Game Night Test',
      body: 'Push reminders are active! You will be alerted before sessions start.',
      payload: 'test_notification',
    );
  }

  /// Schedule 2h and 15m countdown reminders for a game session
  Future<void> scheduleSessionReminders({
    required GameNightModel session,
    required bool isUserAttending,
  }) async {
    final prefs = PreferencesService();

    // If notifications are disabled globally or user is not attending, cancel reminders
    if (!prefs.getPushNotificationsEnabled() || !isUserAttending) {
      await cancelSessionReminders(session.id);
      return;
    }

    if (session.status == GameNightStatus.completed ||
        session.status == GameNightStatus.cancelled) {
      await cancelSessionReminders(session.id);
      return;
    }

    final scheduledTime = session.scheduledDateTime;
    if (scheduledTime == null) return;

    final now = DateTime.now();
    final gameTitle = session.selectedGame?.title ?? session.title;

    // 1. Reminder: 2 Hours Before
    if (prefs.getReminder2HoursEnabled()) {
      final trigger2Hours =
          scheduledTime.subtract(const Duration(hours: 2));
      if (trigger2Hours.isAfter(now)) {
        await _scheduleZonedNotification(
          id: notificationId(session.id, 120),
          title: '🎮 $gameTitle in 2 Hours!',
          body: 'Squad is gathering at ${session.formattedTime}. Get ready!',
          scheduledDate: trigger2Hours,
          payload: session.id,
        );
      }
    } else {
      await cancelNotification(notificationId(session.id, 120));
    }

    // 2. Reminder: 15 Minutes Before
    if (prefs.getReminder15MinsEnabled()) {
      final trigger15Mins =
          scheduledTime.subtract(const Duration(minutes: 15));
      if (trigger15Mins.isAfter(now)) {
        await _scheduleZonedNotification(
          id: notificationId(session.id, 15),
          title: '⚡ 15 Minutes to Game Time!',
          body: '$gameTitle starts at ${session.formattedTime}. Hop in voice!',
          scheduledDate: trigger15Mins,
          payload: session.id,
        );
      }
    } else {
      await cancelNotification(notificationId(session.id, 15));
    }

    // 3. Voting Ballot Reminder (if session is in voting mode)
    if (session.status == GameNightStatus.voting &&
        prefs.getVotingReminderEnabled()) {
      final triggerVote =
          scheduledTime.subtract(const Duration(hours: 6));
      if (triggerVote.isAfter(now)) {
        await _scheduleZonedNotification(
          id: notificationId(session.id, 360),
          title: '🗳️ Game Ballot Closing Soon',
          body: 'Cast your vote for $gameTitle before voting locks!',
          scheduledDate: triggerVote,
          payload: session.id,
        );
      }
    }
  }

  /// Cancels all scheduled reminder notifications for a specific session ID
  Future<void> cancelSessionReminders(String sessionId) async {
    try {
      await _notificationsPlugin.cancel(notificationId(sessionId, 120));
      await _notificationsPlugin.cancel(notificationId(sessionId, 15));
      await _notificationsPlugin.cancel(notificationId(sessionId, 360));
    } catch (e) {
      debugPrint('Error cancelling session reminders: $e');
    }
  }

  /// Cancel a single notification by numeric ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
    }
  }

  /// Cancel all scheduled notifications across the app
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Synchronize scheduled reminders for all upcoming sessions
  Future<void> syncAllSessionReminders({
    required List<GameNightModel> sessions,
    required String currentUserId,
    String? currentUserName,
  }) async {
    final prefs = PreferencesService();
    if (!prefs.getPushNotificationsEnabled()) {
      await cancelAll();
      return;
    }

    for (final s in sessions) {
      final isAttending = _isUserAttending(
        session: s,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      );

      await scheduleSessionReminders(
        session: s,
        isUserAttending: isAttending,
      );
    }
  }

  /// Helper to check attendance
  bool _isUserAttending({
    required GameNightModel session,
    required String currentUserId,
    String? currentUserName,
  }) {
    if (session.organizerName == currentUserName ||
        session.createdBy == currentUserId) {
      return true;
    }

    return session.players.any((p) {
      final normalizedName =
          p.name.replaceAll(' (You)', '').trim().toLowerCase();
      final isUser = (currentUserId.isNotEmpty &&
              currentUserId != 'p1' &&
              currentUserId != 'user-default' &&
              p.id == currentUserId) ||
          (currentUserName != null &&
              currentUserName != 'Player' &&
              normalizedName == currentUserName.trim().toLowerCase()) ||
          (p.id == 'p1' || p.name == 'You' || p.name.contains('(You)'));

      return isUser && p.rsvp == RSVPStatus.going;
    });
  }

  /// Internal helper to schedule a notification at a specific tz.TZDateTime
  Future<void> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final tzLocation = tz.local;
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tzLocation);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        _sessionNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService zonedSchedule note: $e');
    }
  }

  /// Generates a deterministic positive 31-bit integer notification ID
  /// from the session ID and offset minutes.
  static int notificationId(String sessionId, int offsetMinutes) {
    return (sessionId.hashCode ^ offsetMinutes) & 0x7FFFFFFF;
  }
}
