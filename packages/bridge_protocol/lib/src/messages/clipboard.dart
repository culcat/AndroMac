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

  const ClipboardPayload({
    required this.mime,
    required this.data,
    required this.hash,
    required this.origin,
    required this.seq,
  });

  factory ClipboardPayload.fromMap(Map<String, dynamic> map) {
    return ClipboardPayload(
      mime: map['mime'] as String? ?? 'text/plain',
      data: map['data'] as String? ?? '',
      hash: map['hash'] as String? ?? '',
      origin: map['origin'] as String? ?? '',
      seq: map['seq'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mime': mime,
      'data': data,
      'hash': hash,
      'origin': origin,
      'seq': seq,
    };
  }
}
