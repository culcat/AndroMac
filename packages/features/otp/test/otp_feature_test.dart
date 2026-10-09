import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:otp_feature/otp_feature.dart';

class MockTransportChannel implements TransportChannel {
  final _incoming = StreamController<Envelope>.broadcast();
  final List<Envelope> sent = <Envelope>[];
  bool _open = true;

  @override
  Stream<Envelope> get incoming => _incoming.stream;

  @override
  bool get isOpen => _open;

  @override
  void send(Envelope envelope) {
    sent.add(envelope);
  }

  @override
  Future<void> close() async {
    _open = false;
    await _incoming.close();
  }
}

void main() {
  group('OtpFeature', () {
    test('extracts OTP from incoming SMS and triggers callback and stream', () async {
      OtpItem? callbackItem;
      final feature = OtpFeature(
        onOtpDetected: (item) => callbackItem = item,
      );

      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final streamItems = <OtpItem>[];
      feature.onOtp.listen(streamItems.add);

      final smsEnvelope = Envelope.create(
        type: SmsReceivedPayload.messageType,
        payload: const SmsReceivedPayload(
          messageId: 'sms-1',
          threadId: 'th-1',
          address: 'Google',
          body: 'G-748921 is your Google verification code.',
          timestamp: 1760000000000,
        ).toMap(),
      );

      feature.onMessage(smsEnvelope);

      expect(streamItems.length, equals(1));
      expect(streamItems.first.code, equals('748921'));
      expect(streamItems.first.sender, equals('Google'));
      expect(streamItems.first.source, equals('sms'));

      expect(callbackItem, isNotNull);
      expect(callbackItem!.code, equals('748921'));
    });

    test('extracts OTP from incoming notification', () async {
      final feature = OtpFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final streamItems = <OtpItem>[];
      feature.onOtp.listen(streamItems.add);

      final notifEnvelope = Envelope.create(
        type: NotificationPostedPayload.messageTypePosted,
        payload: const NotificationPostedPayload(
          key: 'notif-1',
          packageName: 'org.telegram.messenger',
          appName: 'Telegram',
          title: 'Telegram Security',
          text: 'Login code: 55441. Do not share it.',
          postTime: 1760000000000,
        ).toMap(),
      );

      feature.onMessage(notifEnvelope);

      expect(streamItems.length, equals(1));
      expect(streamItems.first.code, equals('55441'));
      expect(streamItems.first.sender, equals('Telegram'));
      expect(streamItems.first.source, equals('notification'));
    });

    test('ignores non-OTP SMS messages', () async {
      final feature = OtpFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final streamItems = <OtpItem>[];
      feature.onOtp.listen(streamItems.add);

      final casualSms = Envelope.create(
        type: SmsReceivedPayload.messageType,
        payload: const SmsReceivedPayload(
          messageId: 'sms-2',
          threadId: 'th-2',
          address: '+1234567890',
          body: 'Hey, are you free for lunch?',
          timestamp: 1760000000000,
        ).toMap(),
      );

      feature.onMessage(casualSms);
      expect(streamItems, isEmpty);
    });
  });
}
