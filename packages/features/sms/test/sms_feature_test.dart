import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:sms_feature/sms_feature.dart';

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
  group('SmsFeature', () {
    test('sendSms dispatches sms.send envelope and records pending message', () async {
      final feature = SmsFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final clientMsgId = feature.sendSms(
        '+15551234567',
        'Hello from Mac controller!',
        simSlot: 1,
        contactName: 'Alice',
      );

      expect(clientMsgId, isNotNull);
      expect(channel.sent.length, equals(1));

      final sentEnvelope = channel.sent.first;
      expect(sentEnvelope.type, equals(SmsSendPayload.messageType));
      final payload = SmsSendPayload.fromMap(sentEnvelope.payload);
      expect(payload.address, equals('+15551234567'));
      expect(payload.body, equals('Hello from Mac controller!'));
      expect(payload.simSlot, equals(1));
      expect(payload.clientMessageId, equals(clientMsgId));

      // Local store should hold pending message
      expect(feature.store.threadCount, equals(1));
      final thread = feature.store.threads.first;
      expect(thread.contactName, equals('Alice'));
      expect(thread.lastMessage?.status, equals(SmsDeliveryStatus.pending));
    });

    test('receiving sms.sent.status updates message status in store', () async {
      final feature = SmsFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final clientMsgId = feature.sendSms('+15550000000', 'Outgoing');
      expect(clientMsgId, isNotNull);

      // Status envelope arrives confirming delivery
      final statusEnvelope = Envelope.create(
        type: SmsSentStatusPayload.messageType,
        payload: SmsSentStatusPayload(
          clientMessageId: clientMsgId,
          success: true,
        ).toMap(),
      );

      feature.onMessage(statusEnvelope);

      final thread = feature.store.threads.first;
      expect(thread.lastMessage?.status, equals(SmsDeliveryStatus.delivered));
    });

    test('receiving sms.received adds incoming message to store and emits to stream', () async {
      final feature = SmsFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final receivedEvents = <SmsMessageItem>[];
      feature.onMessageReceived.listen(receivedEvents.add);

      final incomingEnvelope = Envelope.create(
        type: SmsReceivedPayload.messageType,
        payload: SmsReceivedPayload(
          messageId: 'phone-msg-1',
          threadId: 'th-555',
          address: '+15559998877',
          body: 'Your 2FA code is 123456',
          timestamp: 1760000000000,
          simSlot: 0,
        ).toMap(),
      );

      feature.onMessage(incomingEnvelope);

      expect(receivedEvents.length, equals(1));
      expect(receivedEvents.first.address, equals('+15559998877'));
      expect(receivedEvents.first.body, contains('123456'));
      expect(feature.store.threadCount, equals(1));
    });

    test('receiving sms.send triggers onSendRequested callback on Android provider', () async {
      SmsSendPayload? capturedPayload;
      String? capturedMessageId;

      final feature = SmsFeature(
        onSendRequested: (payload, msgId) {
          capturedPayload = payload;
          capturedMessageId = msgId;
        },
      );

      final sendEnvelope = Envelope.create(
        type: SmsSendPayload.messageType,
        payload: const SmsSendPayload(
          address: '+15554443322',
          body: 'Remote send request',
          simSlot: 0,
          clientMessageId: 'client-req-9',
        ).toMap(),
      );

      feature.onMessage(sendEnvelope);

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!.address, equals('+15554443322'));
      expect(capturedPayload!.body, equals('Remote send request'));
      expect(capturedMessageId, equals(sendEnvelope.id));
    });
  });
}
