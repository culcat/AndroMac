import 'package:meta/meta.dart';

/// Action button associated with a notification item.
@immutable
class NotificationActionItem {
  final String actionId;
  final String title;
  final bool isQuickReply;

  const NotificationActionItem({
    required this.actionId,
    required this.title,
    this.isQuickReply = false,
  });
}

/// Domain entity representing a mirrored notification.
@immutable
class NotificationItem {
  final String key;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final DateTime postedAt;
  final bool canReply;
  final List<NotificationActionItem> actions;
  final bool isDismissed;

  const NotificationItem({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postedAt,
    this.canReply = false,
    this.actions = const <NotificationActionItem>[],
    this.isDismissed = false,
  });

  NotificationItem copyWith({
    String? key,
    String? packageName,
    String? appName,
    String? title,
    String? text,
    DateTime? postedAt,
    bool? canReply,
    List<NotificationActionItem>? actions,
    bool? isDismissed,
  }) {
    return NotificationItem(
      key: key ?? this.key,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      text: text ?? this.text,
      postedAt: postedAt ?? this.postedAt,
      canReply: canReply ?? this.canReply,
      actions: actions ?? this.actions,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NotificationItem && key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() =>
      'NotificationItem(key: $key, app: $appName, title: $title, dismissed: $isDismissed)';
}
