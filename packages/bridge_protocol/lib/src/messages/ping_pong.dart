import 'package:meta/meta.dart';

/// Payload for heartbeat 'ping'.
@immutable
class PingPayload {
  static const String messageType = 'ping';

  final int timestamp;

  const PingPayload({required this.timestamp});

  factory PingPayload.fromMap(Map<String, dynamic> map) {
    return PingPayload(
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'timestamp': timestamp,
    };
  }
}

/// Payload for heartbeat 'pong'.
@immutable
class PongPayload {
  static const String messageType = 'pong';

  final int timestamp;
  final int receivedTimestamp;

  const PongPayload({
    required this.timestamp,
    required this.receivedTimestamp,
  });

  factory PongPayload.fromMap(Map<String, dynamic> map) {
    return PongPayload(
      timestamp: map['timestamp'] as int? ?? 0,
      receivedTimestamp: map['receivedTimestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'timestamp': timestamp,
      'receivedTimestamp': receivedTimestamp,
    };
  }
}
