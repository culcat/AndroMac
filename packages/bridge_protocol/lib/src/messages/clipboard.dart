import 'package:meta/meta.dart';

/// Payload for 'clipboard.update' message.
@immutable
class ClipboardPayload {
  static const String messageType = 'clipboard.update';

  /// MIME type of the clipboard content (e.g. 'text/plain', 'text/html', 'image/png').
  final String mime;

  /// Content (base64 encoded for binary, raw string for text).
  final String data;

  /// SHA-256 hash of the content to prevent feedback loops.
  final String hash;

  /// Device ID of origin device.
  final String origin;

  /// Monotonically increasing sequence number per device.
  final int seq;

  String get content => data;
  String get mimeType => mime;
  String get originDeviceId => origin;

  const ClipboardPayload({
    String? mime,
    String? mimeType,
    String? data,
    String? content,
    this.hash = '',
    String? origin,
    String? originDeviceId,
    this.seq = 0,
  })  : mime = mime ?? mimeType ?? 'text/plain',
        data = data ?? content ?? '',
        origin = origin ?? originDeviceId ?? '';

  factory ClipboardPayload.fromMap(Map<String, dynamic> map) {
    return ClipboardPayload(
      mime: (map['mime'] ?? map['mimeType']) as String? ?? 'text/plain',
      data: (map['data'] ?? map['content']) as String? ?? '',
      hash: map['hash'] as String? ?? '',
      origin: (map['origin'] ?? map['originDeviceId']) as String? ?? '',
      seq: map['seq'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mime': mime,
      'data': data,
      'content': data,
      'hash': hash,
      'origin': origin,
      'originDeviceId': origin,
      'seq': seq,
    };
  }
}
