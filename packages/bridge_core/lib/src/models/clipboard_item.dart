import 'package:meta/meta.dart';

/// Domain entity representing a synchronized clipboard history entry.
@immutable
class ClipboardItem {
  final String id;
  final String mime;
  final String content;
  final String hash;
  final String originDeviceId;
  final DateTime timestamp;
  final bool isPinned;

  const ClipboardItem({
    required this.id,
    required this.mime,
    required this.content,
    required this.hash,
    required this.originDeviceId,
    required this.timestamp,
    this.isPinned = false,
  });

  ClipboardItem copyWith({
    String? id,
    String? mime,
    String? content,
    String? hash,
    String? originDeviceId,
    DateTime? timestamp,
    bool? isPinned,
  }) {
    return ClipboardItem(
      id: id ?? this.id,
      mime: mime ?? this.mime,
      content: content ?? this.content,
      hash: hash ?? this.hash,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      timestamp: timestamp ?? this.timestamp,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ClipboardItem && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClipboardItem(id: $id, mime: $mime, origin: $originDeviceId, pinned: $isPinned)';
}
