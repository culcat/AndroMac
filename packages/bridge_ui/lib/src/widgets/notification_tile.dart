import 'package:meta/meta.dart';

/// Presentation configuration for a mirrored notification list tile or card.
@immutable
class NotificationTileConfig {
  final String key;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final int postTime;
  final bool canReply;
  final bool isDismissed;

  const NotificationTileConfig({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postTime,
    this.canReply = false,
    this.isDismissed = false,
  });

  /// Formatted time string (HH:mm).
  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(postTime);
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  /// Truncated body preview for compact list tiles.
  String bodySnippet([int maxLength = 80]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// App name badge.
  String get appBadge => '[$appName]';

  /// One-line header representation.
  String get header => '$appName • $formattedTime';

  @override
  String toString() => '$header: $title — ${bodySnippet(40)}';
}
