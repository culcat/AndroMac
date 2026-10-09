import 'dart:convert';
import 'dart:math';
import 'package:meta/meta.dart';

/// Standard protocol envelope wrapping every message exchanged over mTLS WebSocket.
@immutable
class Envelope {
  /// Current protocol major version.
  static const int currentVersion = 1;

  /// Protocol version.
  final int v;

  /// Unique message ID (ULID or UUID string).
  final String id;

  /// Message type in domain.action format (e.g. 'clipboard.update', 'ping').
  final String type;

  /// Timestamp in milliseconds since Unix epoch (sender local time).
  final int ts;

  /// Optional correlation ID pointing to a previous message (for request/response).
  final String? ref;

  /// Type-specific structured message payload.
  final Map<String, dynamic> payload;

  const Envelope({
    this.v = currentVersion,
    required this.id,
    required this.type,
    required this.ts,
    this.ref,
    this.payload = const <String, dynamic>{},
  });

  /// Factory helper to generate a new Envelope with auto-generated ID and timestamp.
  factory Envelope.create({
    required String type,
    Map<String, dynamic> payload = const <String, dynamic>{},
    String? ref,
    int? timestampMs,
    String? id,
  }) {
    return Envelope(
      v: currentVersion,
      id: id ?? generateUlid(),
      type: type,
      ts: timestampMs ?? DateTime.now().millisecondsSinceEpoch,
      ref: ref,
      payload: payload,
    );
  }

  /// Deserializes an envelope from a decoded JSON map.
  factory Envelope.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('v') || json['v'] is! int) {
      throw FormatException('Missing or invalid "v" field in envelope: $json');
    }
    if (!json.containsKey('id') || json['id'] is! String) {
      throw FormatException('Missing or invalid "id" field in envelope: $json');
    }
    if (!json.containsKey('type') || json['type'] is! String) {
      throw FormatException('Missing or invalid "type" field in envelope: $json');
    }
    if (!json.containsKey('ts') || json['ts'] is! int) {
      throw FormatException('Missing or invalid "ts" field in envelope: $json');
    }

    final rawPayload = json['payload'];
    final Map<String, dynamic> payloadMap;
    if (rawPayload is Map<String, dynamic>) {
      payloadMap = rawPayload;
    } else if (rawPayload is Map) {
      payloadMap = Map<String, dynamic>.from(rawPayload);
    } else {
      payloadMap = const <String, dynamic>{};
    }

    return Envelope(
      v: json['v'] as int,
      id: json['id'] as String,
      type: json['type'] as String,
      ts: json['ts'] as int,
      ref: json['ref'] as String?,
      payload: payloadMap,
    );
  }

  /// Decodes a JSON string into an Envelope.
  factory Envelope.decode(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Envelope JSON must be a JSON object');
    }
    return Envelope.fromJson(decoded);
  }

  /// Converts the envelope into a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'v': v,
      'id': id,
      'type': type,
      'ts': ts,
      if (ref != null) 'ref': ref,
      'payload': payload,
    };
  }

  /// Encodes the envelope into a JSON string.
  String encode() => jsonEncode(toJson());

  Envelope copyWith({
    int? v,
    String? id,
    String? type,
    int? ts,
    String? ref,
    Map<String, dynamic>? payload,
  }) {
    return Envelope(
      v: v ?? this.v,
      id: id ?? this.id,
      type: type ?? this.type,
      ts: ts ?? this.ts,
      ref: ref ?? this.ref,
      payload: payload ?? this.payload,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Envelope &&
          runtimeType == other.runtimeType &&
          v == other.v &&
          id == other.id &&
          type == other.type &&
          ts == other.ts &&
          ref == other.ref;

  @override
  int get hashCode => Object.hash(v, id, type, ts, ref);

  @override
  String toString() => 'Envelope(v: $v, id: $id, type: $type, ts: $ts, ref: $ref)';

  /// Simple Crockford Base32-like ULID generator without external dependencies.
  static String generateUlid([int? timeMs]) {
    const encoding = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    final now = timeMs ?? DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();

    // 10 chars of timestamp (48 bits)
    final timeChars = List<String>.filled(10, '0');
    var t = now;
    for (var i = 9; i >= 0; i--) {
      timeChars[i] = encoding[t % 32];
      t ~/= 32;
    }

    // 16 chars of randomness (80 bits)
    final randChars = List<String>.generate(16, (_) => encoding[random.nextInt(32)]);

    return '${timeChars.join()}${randChars.join()}';
  }
}
