import 'package:flutter/material.dart';
import '../../core/theme/duwa_theme.dart';
import '../../models/notification_model.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../common/duwa_buttons.dart';
import '../common/duwa_cards.dart';
import '../common/state_feedback_views.dart';

class NotificationsView extends StatelessWidget {
  final NotificationsViewModel notificationsVm;
  final DuwaThemeData duwaTheme;

  const NotificationsView({
    super.key,
    required this.notificationsVm,
    required this.duwaTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificationsVm,
      builder: (context, _) {
        final notifications = notificationsVm.notifications;
        final selectedCategory = notificationsVm.selectedCategory;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Activity & Alerts'),
            actions: [
              if (notificationsVm.unreadCount > 0)
                TextButton(
                  onPressed: () => notificationsVm.markAllAsRead(),
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          body: Column(
            children: [
              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    DuwaFilterChip(
                      label: 'All',
                      isSelected: selectedCategory == null,
                      onTap: () => notificationsVm.selectCategory(null),
                    ),
                    const SizedBox(width: 8),
                    DuwaFilterChip(
                      label: 'Votes',
                      emoji: '🎮',
                      isSelected: selectedCategory == NotificationCategory.vote,
                      onTap: () => notificationsVm.selectCategory(NotificationCategory.vote),
                    ),
                    const SizedBox(width: 8),
                    DuwaFilterChip(
                      label: 'Food',
                      emoji: '🍕',
                      isSelected: selectedCategory == NotificationCategory.food,
                      onTap: () => notificationsVm.selectCategory(NotificationCategory.food),
                    ),
                    const SizedBox(width: 8),
                    DuwaFilterChip(
                      label: 'Squad',
                      emoji: '👥',
                      isSelected: selectedCategory == NotificationCategory.group,
                      onTap: () => notificationsVm.selectCategory(NotificationCategory.group),
                    ),
                    const SizedBox(width: 8),
                    DuwaFilterChip(
                      label: 'Things to Bring',
                      emoji: '🎒',
                      isSelected: selectedCategory == NotificationCategory.prep,
                      onTap: () => notificationsVm.selectCategory(NotificationCategory.prep),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Notifications List
              Expanded(
                child: notifications.isEmpty
                    ? EmptyStateWidget.notifications()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return DuwaCard(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 10),
                            onTap: () => notificationsVm.toggleRead(item.id),
                            border: Border.all(
                              color: item.isRead
                                  ? Colors.white.withAlpha(15)
                                  : duwaTheme.highlight.withAlpha(70),
                              width: item.isRead ? 1 : 1.5,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: duwaTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(item.iconEmoji, style: const TextStyle(fontSize: 20)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: item.isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            item.timeAgo,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: duwaTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subtitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: item.isRead
                                              ? duwaTheme.textMuted
                                              : duwaTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: duwaTheme.highlight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
