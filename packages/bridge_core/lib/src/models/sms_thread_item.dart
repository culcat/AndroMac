import 'package:meta/meta.dart';

/// Delivery status of an SMS message.
enum SmsDeliveryStatus {
  pending,
  sent,
  delivered,
  failed,
}

/// Domain entity for an individual SMS message.
@immutable
class SmsMessageItem {
  final String id;
  final String threadId;
  final String address;
  final String body;
  final DateTime timestamp;
  final bool isOutgoing;
  final int simSlot;
  final SmsDeliveryStatus status;

  const SmsMessageItem({
    required this.id,
    required this.threadId,
    required this.address,
    required this.body,
    required this.timestamp,
    this.isOutgoing = false,
    this.simSlot = 0,
    this.status = SmsDeliveryStatus.delivered,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SmsMessageItem && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SmsMessageItem(id: $id, threadId: $threadId, address: $address, outgoing: $isOutgoing)';
}

/// Domain entity representing an SMS conversation thread.
@immutable
class SmsThreadItem {
  final String threadId;
  final String address;
  final String? contactName;
  final SmsMessageItem? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const SmsThreadItem({
    required this.threadId,
    required this.address,
    this.contactName,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  String get displayName =>
      (contactName != null && contactName!.isNotEmpty) ? contactName! : address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsThreadItem && threadId == other.threadId;

  @override
  int get hashCode => threadId.hashCode;

  @override
  String toString() =>
      'SmsThreadItem(threadId: $threadId, name: $displayName, unread: $unreadCount)';
}
