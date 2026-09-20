import 'package:flutter/material.dart';
import '../models/game_night_model.dart';
import '../models/group_model.dart';
import '../models/notification_model.dart';
import '../services/preferences_service.dart';

class NotificationsViewModel extends ChangeNotifier {
  NotificationCategory? _selectedCategory;
  NotificationCategory? get selectedCategory => _selectedCategory;

  final List<NotificationModel> _notifications;

  NotificationsViewModel({bool withFixtureData = false})
      : _notifications = withFixtureData ? _fixtureNotifications() : [];

  factory NotificationsViewModel.withFixtureData() =>
      NotificationsViewModel(withFixtureData: true);

  static List<NotificationModel> _fixtureNotifications() => [
        const NotificationModel(
          id: 'n1',
          title: 'Squad invited you to Friday Valorant Session',
          subtitle: '8:00 PM · Valorant session',
          timeAgo: 'Just now',
          iconEmoji: '🎮',
          category: NotificationCategory.reminder,
          isRead: false,
        ),
        const NotificationModel(
          id: 'n2',
          title: 'Vote for the game before Friday',
          subtitle: 'Valorant and Dota 2 are tied! Cast your vote',
          timeAgo: '15m ago',
          iconEmoji: '🗳️',
          category: NotificationCategory.vote,
          isRead: false,
        ),
      ];

  /// Dynamically synchronizes in-app notifications with active sessions:
  /// - Upcoming game nights (< 48h)
  /// - Active game ballots requiring votes
  /// - Sessions waiting for squad player response
  void syncWithSessions({
    required List<GameNightModel> sessions,
    required String currentUserId,
    String? currentUserName,
  }) {
    final readIds = PreferencesService().getReadNotificationIds();
    final List<NotificationModel> generated = [];
    final now = DateTime.now();

    for (final s in sessions) {
      if (s.status == GameNightStatus.completed ||
          s.status == GameNightStatus.cancelled) {
        continue;
      }

      final myPlayer = s.players.firstWhere(
        (p) {
          final normalizedName =
              p.name.replaceAll(' (You)', '').trim().toLowerCase();
          if (currentUserId.isNotEmpty && currentUserId != 'p1' && currentUserId != 'user-default' && p.id == currentUserId) {
            return true;
          }
          if (currentUserName != null && currentUserName != 'Player' && normalizedName == currentUserName.trim().toLowerCase()) {
            return true;
          }
          if ((currentUserId.isEmpty || currentUserId == 'p1' || currentUserId == 'user-default') &&
              (p.id == 'p1' || p.name == 'You' || p.name.contains('(You)'))) {
            return true;
          }
          return false;
        },
        orElse: () => const PlayerModel(
          id: '',
          name: '',
          username: '',
          avatarInitials: '',
          avatarColorIndex: 0,
          rsvp: RSVPStatus.maybe,
        ),
      );

      final isGoing = myPlayer.rsvp == RSVPStatus.going;
      final isPending = myPlayer.id.isEmpty || myPlayer.rsvp == RSVPStatus.maybe;

      final titleText = s.selectedGame?.title ?? s.title;

      // 1. Voting Ballot Active Notification
      if (s.status == GameNightStatus.voting && s.votingGames.isNotEmpty) {
        final id = 'notif_vote_${s.id}';
        generated.add(NotificationModel(
          id: id,
          title: 'Game Ballot: $titleText',
          subtitle: 'Vote for what game to play · ${s.group.name}',
          timeAgo: s.formattedDate,
          iconEmoji: '🗳️',
          category: NotificationCategory.vote,
          isRead: readIds.contains(id),
        ));
      }

      // 2. Upcoming Session Reminder (< 48h and player is going)
      if (s.status == GameNightStatus.ready ||
          s.status == GameNightStatus.planning) {
        final sessionTime = s.scheduledDateTime ?? now.add(const Duration(hours: 4));
        final hoursUntil = sessionTime.difference(now).inHours;
        if (hoursUntil >= 0 && hoursUntil <= 48 && isGoing) {
          final id = 'notif_reminder_${s.id}';
          final urgency = hoursUntil <= 3
              ? 'Starting soon'
              : 'At ${s.formattedTime}';
          generated.add(NotificationModel(
            id: id,
            title: '$titleText · $urgency',
            subtitle: '${s.formattedDate} · ${s.group.name}',
            timeAgo: s.formattedDate,
            iconEmoji: '⏰',
            category: NotificationCategory.reminder,
            isRead: readIds.contains(id),
          ));
        }
      }

      // 3. Needs your response / spot confirmation
      if (isPending) {
        final id = 'notif_rsvp_${s.id}';
        generated.add(NotificationModel(
          id: id,
          title: 'Squad Invite: $titleText',
          subtitle: '${s.formattedDate} · ${s.formattedTime} · ${s.group.name}',
          timeAgo: s.formattedDate,
          iconEmoji: '🎮',
          category: NotificationCategory.group,
          isRead: readIds.contains(id),
        ));
      }
    }

    final existingExplicit =
        _notifications.where((n) => !n.id.startsWith('notif_')).toList();

    _notifications
      ..clear()
      ..addAll(generated)
      ..addAll(existingExplicit);

    notifyListeners();
  }

  void addNotification(NotificationModel item) {
    _notifications.insert(0, item);
    notifyListeners();
  }

  List<NotificationModel> get notifications {
    if (_selectedCategory == null) return List.unmodifiable(_notifications);
    return _notifications.where((n) => n.category == _selectedCategory).toList();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void selectCategory(NotificationCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
      PreferencesService().markNotificationRead(_notifications[i].id);
    }
    notifyListeners();
  }

  void toggleRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final updatedRead = !_notifications[index].isRead;
      _notifications[index] = _notifications[index].copyWith(
        isRead: updatedRead,
      );
      if (updatedRead) {
        PreferencesService().markNotificationRead(id);
      }
      notifyListeners();
    }
  }

  /// Clear all in-memory notifications (called on logout/account switch)
  void clearNotifications() {
    _notifications.clear();
    _selectedCategory = null;
    notifyListeners();
  }
}
