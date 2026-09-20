import 'package:flutter/material.dart';
import '../../core/theme/duwa_theme.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../common/bouncy_tap.dart';
import '../common/state_feedback_views.dart';

class NotificationsView extends StatefulWidget {
  final NotificationsViewModel notificationsVm;
  final DuwaThemeData duwaTheme;

  const NotificationsView({
    super.key,
    required this.notificationsVm,
    required this.duwaTheme,
  });

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  bool _showOnlyUnread = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.duwaTheme;

    return ListenableBuilder(
      listenable: widget.notificationsVm,
      builder: (context, _) {
        final allNotifications = widget.notificationsVm.notifications;
        final unreadCount = widget.notificationsVm.unreadCount;
        final notifications = _showOnlyUnread
            ? allNotifications.where((n) => !n.isRead).toList()
            : allNotifications;

        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.background,
            elevation: 0,
            title: Text(
              'Alerts',
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => widget.notificationsVm.markAllAsRead(),
                  child: Text(
                    'Mark read',
                    style: TextStyle(
                      color: t.primaryAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Simplified 2-state filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Row(
                  children: [
                    _buildFilterPill(
                      label: 'All (${allNotifications.length})',
                      isSelected: !_showOnlyUnread,
                      onTap: () => setState(() => _showOnlyUnread = false),
                      t: t,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'Unread ($unreadCount)',
                      isSelected: _showOnlyUnread,
                      onTap: () => setState(() => _showOnlyUnread = true),
                      t: t,
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: t.cardBorder.withAlpha(120)),

              // Notifications List
              Expanded(
                child: notifications.isEmpty
                    ? EmptyStateWidget.notifications()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: BouncyTap(
                              onTap: () => widget.notificationsVm.toggleRead(item.id),
                              scaleDown: 0.98,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: item.isRead
                                      ? t.surface
                                      : t.surfaceLight,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: item.isRead
                                        ? t.cardBorder
                                        : t.primaryAccent.withAlpha(110),
                                    width: item.isRead ? 0.8 : 1.4,
                                  ),
                                  boxShadow: DuwaTheme.cozyShadow,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: item.isRead
                                            ? t.secondaryContainer.withAlpha(140)
                                            : t.primaryAccent.withAlpha(25),
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: item.isRead
                                              ? Colors.transparent
                                              : t.primaryAccent.withAlpha(60),
                                          width: 0.8,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        item.iconEmoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: item.isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.w800,
                                                    color: t.textPrimary,
                                                    letterSpacing: -0.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                item.timeAgo,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: item.isRead
                                                      ? t.textMuted
                                                      : t.primaryAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            item.subtitle,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              height: 1.38,
                                              color: item.isRead
                                                  ? t.textSecondary
                                                  : t.textPrimary.withAlpha(225),
                                              fontWeight: item.isRead
                                                  ? FontWeight.w400
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!item.isRead) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          color: t.primaryAccent,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: t.primaryAccent.withAlpha(120),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required DuwaThemeData t,
  }) {
    return BouncyTap(
      onTap: onTap,
      scaleDown: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? t.primaryAccent : t.surfaceLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? t.primaryAccent : t.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : t.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
