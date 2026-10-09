import 'package:meta/meta.dart';

/// Payload for 'error' message.
@immutable
class ErrorPayload {
  static const String messageType = 'error';

  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const ErrorPayload({
    required this.code,
    required this.message,
    this.details,
  });

  factory ErrorPayload.fromMap(Map<String, dynamic> map) {
    return ErrorPayload(
      code: map['code'] as String? ?? 'UNKNOWN_ERROR',
      message: map['message'] as String? ?? '',
      details: map['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'message': message,
      if (details != null) 'details': details,
    };
  }
}
