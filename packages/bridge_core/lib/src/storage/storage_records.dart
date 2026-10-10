import 'package:meta/meta.dart';

/// Persistence entity for SMS messages in the local encrypted storage.
@immutable
class SmsRecord {
  final String id;
  final String threadId;
  final String address;
  final String body;
  final int timestamp;
  final int simSlot;
  final String deliveryStatus; // 'sending', 'sent', 'delivered', 'failed'

  const SmsRecord({
    required this.id,
    required this.threadId,
    required this.address,
    required this.body,
    required this.timestamp,
    this.simSlot = 0,
    this.deliveryStatus = 'sent',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'threadId': threadId,
        'address': address,
        'body': body,
        'timestamp': timestamp,
        'simSlot': simSlot,
        'deliveryStatus': deliveryStatus,
      };

  factory SmsRecord.fromMap(Map<String, dynamic> map) => SmsRecord(
        id: map['id'] as String,
        threadId: map['threadId'] as String,
        address: map['address'] as String,
        body: map['body'] as String,
        timestamp: map['timestamp'] as int,
        simSlot: map['simSlot'] as int? ?? 0,
        deliveryStatus: map['deliveryStatus'] as String? ?? 'sent',
      );
}

/// Persistence entity for mirrored notifications with 7-day TTL retention.
@immutable
class NotificationRecord {
  final String key;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final int postTime;
  final bool canReply;
  final bool isDismissed;

  const NotificationRecord({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postTime,
    this.canReply = false,
    this.isDismissed = false,
  });

  NotificationRecord copyWith({bool? isDismissed}) => NotificationRecord(
        key: key,
        packageName: packageName,
        appName: appName,
        title: title,
        text: text,
        postTime: postTime,
        canReply: canReply,
        isDismissed: isDismissed ?? this.isDismissed,
      );

  Map<String, dynamic> toMap() => {
        'key': key,
        'packageName': packageName,
        'appName': appName,
        'title': title,
        'text': text,
        'postTime': postTime,
        'canReply': canReply,
        'isDismissed': isDismissed,
      };

  factory NotificationRecord.fromMap(Map<String, dynamic> map) =>
      NotificationRecord(
        key: map['key'] as String,
        packageName: map['packageName'] as String,
        appName: map['appName'] as String,
        title: map['title'] as String,
        text: map['text'] as String,
        postTime: map['postTime'] as int,
        canReply: map['canReply'] as bool? ?? false,
        isDismissed: map['isDismissed'] as bool? ?? false,
      );
}

/// Persistence entity for clipboard history items.
@immutable
class ClipboardRecord {
  final String id;
  final String content;
  final String mimeType;
  final String originDeviceId;
  final String? hash;
  final bool isPinned;
  final int timestamp;

  const ClipboardRecord({
    required this.id,
    required this.content,
    this.mimeType = 'text/plain',
    required this.originDeviceId,
    this.hash,
    this.isPinned = false,
    required this.timestamp,
  });

  ClipboardRecord copyWith({bool? isPinned}) => ClipboardRecord(
        id: id,
        content: content,
        mimeType: mimeType,
        originDeviceId: originDeviceId,
        hash: hash,
        isPinned: isPinned ?? this.isPinned,
        timestamp: timestamp,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'mimeType': mimeType,
        'originDeviceId': originDeviceId,
        'hash': hash,
        'isPinned': isPinned,
        'timestamp': timestamp,
      };

  factory ClipboardRecord.fromMap(Map<String, dynamic> map) => ClipboardRecord(
        id: map['id'] as String,
        content: map['content'] as String,
        mimeType: map['mimeType'] as String? ?? 'text/plain',
        originDeviceId: map['originDeviceId'] as String,
        hash: map['hash'] as String?,
        isPinned: map['isPinned'] as bool? ?? false,
        timestamp: map['timestamp'] as int,
      );
}

/// Persistence entity for paired devices and trusted certificate fingerprints.
@immutable
class DeviceRecord {
  final String deviceId;
  final String name;
  final String platform;
  final String certificateFingerprint;
  final int lastSeen;

  const DeviceRecord({
    required this.deviceId,
    required this.name,
    required this.platform,
    required this.certificateFingerprint,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() => {
        'deviceId': deviceId,
        'name': name,
        'platform': platform,
        'certificateFingerprint': certificateFingerprint,
        'lastSeen': lastSeen,
      };

  factory DeviceRecord.fromMap(Map<String, dynamic> map) => DeviceRecord(
        deviceId: map['deviceId'] as String,
        name: map['name'] as String,
        platform: map['platform'] as String,
        certificateFingerprint: map['certificateFingerprint'] as String,
        lastSeen: map['lastSeen'] as int,
      );
}
