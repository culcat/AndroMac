import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_core/bridge_core.dart';
import 'otp_extractor.dart';
import 'otp_model.dart';

/// Feature plugin listening to incoming SMS and notifications to extract 2FA/OTP verification codes.
class OtpFeature implements BridgeFeature {
  @override
  final String id = 'otp';

  @override
  final Set<String> incomingTypes = const <String>{
    SmsReceivedPayload.messageType,
    NotificationPostedPayload.messageTypePosted,
  };

  final StreamController<OtpItem> _otpController =
      StreamController<OtpItem>.broadcast();

  FeatureContext? _context;

  /// Currently attached [FeatureContext].
  FeatureContext? get context => _context;

  /// Optional callback invoked when a verification code is extracted (e.g. for automatic clipboard copy).
  void Function(OtpItem item)? onOtpDetected;

  OtpFeature({this.onOtpDetected});

  /// Stream of detected one-time verification codes.
  Stream<OtpItem> get onOtp => _otpController.stream;

  @override
  Future<void> start(FeatureContext ctx) async {
    _context = ctx;
  }

  @override
  Future<void> stop() async {
    _context = null;
  }

  @override
  void onMessage(Envelope message) {
    if (message.type == SmsReceivedPayload.messageType) {
      _processSms(message);
    } else if (message.type == NotificationPostedPayload.messageTypePosted) {
      _processNotification(message);
    }
  }

  void _processSms(Envelope message) {
    final payload = SmsReceivedPayload.fromMap(message.payload);
    final code = OtpExtractor.extract(payload.body);

    if (code != null) {
      final item = OtpItem(
        code: code,
        sender: payload.address,
        fullText: payload.body,
        source: 'sms',
        timestamp: DateTime.fromMillisecondsSinceEpoch(payload.timestamp),
      );

      _otpController.add(item);
      onOtpDetected?.call(item);
    }
  }

  void _processNotification(Envelope message) {
    final payload = NotificationPostedPayload.fromMap(message.payload);
    final combinedText = '${payload.title} ${payload.text}';
    final code = OtpExtractor.extract(combinedText);

    if (code != null) {
      final item = OtpItem(
        code: code,
        sender:
            payload.appName.isNotEmpty ? payload.appName : payload.packageName,
        fullText: payload.text,
        source: 'notification',
        timestamp: DateTime.fromMillisecondsSinceEpoch(payload.postTime),
      );

      _otpController.add(item);
      onOtpDetected?.call(item);
    }
  }

  void dispose() {
    _otpController.close();
  }
}
