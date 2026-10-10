import 'package:meta/meta.dart';

/// Presentation configuration for a clipboard history item tile.
@immutable
class ClipboardTileConfig {
  final String id;
  final String content;
  final String mimeType;
  final String originDeviceId;
  final bool isPinned;
  final int timestamp;

  const ClipboardTileConfig({
    required this.id,
    required this.content,
    this.mimeType = 'text/plain',
    required this.originDeviceId,
    this.isPinned = false,
    required this.timestamp,
  });

  /// Character count of the content.
  int get charCount => content.length;

  /// Formatted time (HH:mm).
  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  /// Truncated preview snippet.
  String snippet([int maxLength = 60]) {
    final singleLine = content.replaceAll('\n', ' ').trim();
    if (singleLine.length <= maxLength) return singleLine;
    return '${singleLine.substring(0, maxLength)}...';
  }

  /// Origin device label indicator.
  String get originBadge {
    if (originDeviceId.toLowerCase().contains('mac')) {
      return '💻 macOS';
    } else if (originDeviceId.toLowerCase().contains('phone') ||
        originDeviceId.toLowerCase().contains('android')) {
      return '📱 Android';
    }
    return '🔗 $originDeviceId';
  }

  /// Pin state indicator symbol.
  String get pinSymbol => isPinned ? '📌' : '';

  @override
  String toString() => '$originBadge $pinSymbol $formattedTime: ${snippet(30)}';
}
