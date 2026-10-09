import 'package:meta/meta.dart';

/// Payload for 'notif.posted' or 'notif.updated'.
@immutable
class NotificationPostedPayload {
  static const String messageTypePosted = 'notif.posted';
  static const String messageTypeUpdated = 'notif.updated';

  final String key; // Unique system key for notification
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final int postTime;
  final bool canReply;
  final List<NotificationAction> actions;

  const NotificationPostedPayload({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postTime,
    this.canReply = false,
    this.actions = const <NotificationAction>[],
  });

  factory NotificationPostedPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPostedPayload(
      key: map['key'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      postTime: map['postTime'] as int? ?? 0,
      canReply: map['canReply'] as bool? ?? false,
      actions: (map['actions'] as List<dynamic>?)
              ?.map((e) => NotificationAction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const <NotificationAction>[],
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'packageName': packageName,
      'appName': appName,
      'title': title,
      'text': text,
      'postTime': postTime,
      'canReply': canReply,
      'actions': actions.map((a) => a.toMap()).toList(),
    };
  }
}

/// Action button inside a notification.
@immutable
class NotificationAction {
  final String actionId;
  final String title;
  final bool isQuickReply;

  const NotificationAction({
    required this.actionId,
    required this.title,
    this.isQuickReply = false,
  });

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      actionId: map['actionId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isQuickReply: map['isQuickReply'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'actionId': actionId,
      'title': title,
      'isQuickReply': isQuickReply,
    };
  }
}

/// Payload for 'notif.dismiss' message (Mac -> Phone).
@immutable
class NotificationDismissPayload {
  static const String messageType = 'notif.dismiss';

  final String key;

  const NotificationDismissPayload({required this.key});

  factory NotificationDismissPayload.fromMap(Map<String, dynamic> map) {
    return NotificationDismissPayload(
      key: map['key'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
    };
  }
}

/// Payload for 'notif.action' (Mac -> Phone: reply or trigger action).
@immutable
class NotificationActionPayload {
  static const String messageType = 'notif.action';

  final String key;
  final String actionId;
  final String? replyText; // For RemoteInput quick reply

  const NotificationActionPayload({
    required this.key,
    required this.actionId,
    this.replyText,
  });

  factory NotificationActionPayload.fromMap(Map<String, dynamic> map) {
    return NotificationActionPayload(
      key: map['key'] as String? ?? '',
      actionId: map['actionId'] as String? ?? '',
      replyText: map['replyText'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'actionId': actionId,
      if (replyText != null) 'replyText': replyText,
    };
  }
}
