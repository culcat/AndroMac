import 'package:meta/meta.dart';

/// Payload for 'hello' handshake message.
@immutable
class HelloPayload {
  static const String messageType = 'hello';

  final String deviceId;
  final String name;
  final String platform; // 'android' | 'macos'
  final String appVersion;
  final int protocolVersion;
  final List<String> capabilities;

  const HelloPayload({
    required this.deviceId,
    required this.name,
    required this.platform,
    required this.appVersion,
    required this.protocolVersion,
    required this.capabilities,
  });

  factory HelloPayload.fromMap(Map<String, dynamic> map) {
    return HelloPayload(
      deviceId: map['deviceId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      appVersion: map['appVersion'] as String? ?? '',
      protocolVersion: map['protocolVersion'] as int? ?? 1,
      capabilities: (map['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'name': name,
      'platform': platform,
      'appVersion': appVersion,
      'protocolVersion': protocolVersion,
      'capabilities': capabilities,
    };
  }
}

/// Payload for 'hello.ack' handshake acknowledgement.
@immutable
class HelloAckPayload {
  static const String messageType = 'hello.ack';

  final bool accepted;
  final String deviceId;
  final List<String> agreedCapabilities;
  final String? rejectionReason;

  const HelloAckPayload({
    required this.accepted,
    required this.deviceId,
    required this.agreedCapabilities,
    this.rejectionReason,
  });

  factory HelloAckPayload.fromMap(Map<String, dynamic> map) {
    return HelloAckPayload(
      accepted: map['accepted'] as bool? ?? false,
      deviceId: map['deviceId'] as String? ?? '',
      agreedCapabilities: (map['agreedCapabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'accepted': accepted,
      'deviceId': deviceId,
      'agreedCapabilities': agreedCapabilities,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }
}
