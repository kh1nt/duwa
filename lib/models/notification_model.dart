enum NotificationCategory {
  vote,
  group,
  food,
  reminder,
  prep,
}

class NotificationModel {
  final String id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String iconEmoji;
  final NotificationCategory category;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.iconEmoji,
    required this.category,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? timeAgo,
    String? iconEmoji,
    NotificationCategory? category,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      timeAgo: timeAgo ?? this.timeAgo,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
    );
  }
}
