import 'package:meta/meta.dart';

/// Payload for 'sms.received' event (Phone -> Mac).
@immutable
class SmsReceivedPayload {
  static const String messageType = 'sms.received';

  final String messageId;
  final String threadId;
  final String address; // Phone number or sender alphanumeric
  final String body;
  final int timestamp;
  final int simSlot; // 0 for primary, 1 for secondary (dual SIM)

  const SmsReceivedPayload({
    required this.messageId,
    required this.threadId,
    required this.address,
    required this.body,
    required this.timestamp,
    this.simSlot = 0,
  });

  factory SmsReceivedPayload.fromMap(Map<String, dynamic> map) {
    return SmsReceivedPayload(
      messageId: map['messageId'] as String? ?? '',
      threadId: map['threadId'] as String? ?? '',
      address: map['address'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
      simSlot: map['simSlot'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messageId': messageId,
      'threadId': threadId,
      'address': address,
      'body': body,
      'timestamp': timestamp,
      'simSlot': simSlot,
    };
  }
}

/// Payload for 'sms.send' command (Mac -> Phone).
@immutable
class SmsSendPayload {
  static const String messageType = 'sms.send';

  final String address;
  final String body;
  final int simSlot;
  final String? clientMessageId; // For client-side tracking

  const SmsSendPayload({
    required this.address,
    required this.body,
    this.simSlot = 0,
    this.clientMessageId,
  });

  factory SmsSendPayload.fromMap(Map<String, dynamic> map) {
    return SmsSendPayload(
      address: map['address'] as String? ?? '',
      body: map['body'] as String? ?? '',
      simSlot: map['simSlot'] as int? ?? 0,
      clientMessageId: map['clientMessageId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'address': address,
      'body': body,
      'simSlot': simSlot,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    };
  }
}

/// Payload for 'sms.sent.status' confirmation (Phone -> Mac).
@immutable
class SmsSentStatusPayload {
  static const String messageType = 'sms.sent.status';

  final String? clientMessageId;
  final bool success;
  final String? error;

  const SmsSentStatusPayload({
    this.clientMessageId,
    required this.success,
    this.error,
  });

  factory SmsSentStatusPayload.fromMap(Map<String, dynamic> map) {
    return SmsSentStatusPayload(
      clientMessageId: map['clientMessageId'] as String?,
      success: map['success'] as bool? ?? false,
      error: map['error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
      'success': success,
      if (error != null) 'error': error,
    };
  }
}
