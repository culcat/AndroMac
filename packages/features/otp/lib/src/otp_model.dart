import 'package:meta/meta.dart';

/// Domain entity representing a detected one-time verification or 2FA code.
@immutable
class OtpItem {
  final String code;
  final String sender;
  final String fullText;
  final String source; // 'sms' | 'notification'
  final DateTime timestamp;

  const OtpItem({
    required this.code,
    required this.sender,
    required this.fullText,
    required this.source,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OtpItem &&
          code == other.code &&
          sender == other.sender &&
          source == other.source;

  @override
  int get hashCode => Object.hash(code, sender, source);

  @override
  String toString() => 'OtpItem(code: $code, sender: $sender, source: $source)';
}
