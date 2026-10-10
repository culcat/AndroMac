import 'package:meta/meta.dart';

/// Presentation configuration for an SMS conversation thread tile in the inbox view.
@immutable
class SmsConversationTileConfig {
  final String threadId;
  final String? contactName;
  final String phoneNumber;
  final String lastMessageSnippet;
  final int unreadCount;
  final int lastTimestamp;

  const SmsConversationTileConfig({
    required this.threadId,
    this.contactName,
    required this.phoneNumber,
    required this.lastMessageSnippet,
    this.unreadCount = 0,
    required this.lastTimestamp,
  });

  /// Display name preferring contact name over phone number.
  String get displayName =>
      (contactName != null && contactName!.trim().isNotEmpty)
          ? contactName!
          : phoneNumber;

  /// Derived initials for avatar rendering.
  String get avatarInitials {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Formatted timestamp (HH:mm).
  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  /// Indicates if there are unread messages in this conversation.
  bool get hasUnread => unreadCount > 0;
}

/// Presentation configuration for an individual SMS chat message bubble.
@immutable
class SmsMessageBubbleConfig {
  final String messageId;
  final String body;
  final bool isOutbound;
  final int timestamp;
  final int simSlot;
  final String deliveryStatus; // 'sending', 'sent', 'delivered', 'failed'

  const SmsMessageBubbleConfig({
    required this.messageId,
    required this.body,
    required this.isOutbound,
    required this.timestamp,
    this.simSlot = 0,
    this.deliveryStatus = 'sent',
  });

  /// Status delivery indicator tick symbol.
  String get statusTick {
    if (!isOutbound) return '';
    switch (deliveryStatus.toLowerCase()) {
      case 'sending':
        return '⏳';
      case 'delivered':
        return '✓✓';
      case 'failed':
        return '⚠️';
      case 'sent':
      default:
        return '✓';
    }
  }

  /// Multi-SIM slot label.
  String get simBadge => 'SIM ${simSlot + 1}';

  /// Formatted message time (HH:mm).
  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}
