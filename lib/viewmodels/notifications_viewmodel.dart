import 'package:flutter/material.dart';
import '../models/notification_model.dart';

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
    }
    notifyListeners();
  }

  void toggleRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: !_notifications[index].isRead,
      );
      notifyListeners();
    }
  }
}
