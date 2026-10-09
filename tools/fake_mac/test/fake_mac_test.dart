import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:fake_mac/fake_mac.dart';

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

  void pushMessage(Envelope envelope) {
    _incoming.add(envelope);
  }
}

void main() {
  group('FakeMacController', () {
    test('attach sends hello handshake message', () async {
      final controller = FakeMacController(name: 'Test Mac Studio');
      final channel = MockTransportChannel();

      await controller.attach(channel);

      expect(channel.sent.length, equals(1));
      final hello = channel.sent.first;
      expect(hello.type, equals(HelloPayload.messageType));
      expect(hello.payload['name'], equals('Test Mac Studio'));
      expect(hello.payload['platform'], equals('macos'));
    });

    test('responds to phone hello with hello.ack', () async {
      final controller = FakeMacController();
      final channel = MockTransportChannel();
      await controller.attach(channel);

      final phoneHello = Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'phone-pixel',
          name: 'Pixel 8',
          platform: 'android',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['clipboard', 'notifications', 'sms'],
        ).toMap(),
      );

      channel.pushMessage(phoneHello);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final ack = channel.sent.last;
      expect(ack.type, equals(HelloAckPayload.messageType));
      expect(ack.ref, equals(phoneHello.id));
      final ackPayload = HelloAckPayload.fromMap(ack.payload);
      expect(ackPayload.accepted, isTrue);
      expect(ackPayload.agreedCapabilities, containsAll(['clipboard', 'notifications', 'sms']));
    });

    test('sendSms dispatches sms.send envelope with clientMessageId', () async {
      final controller = FakeMacController();
      final channel = MockTransportChannel();
      await controller.attach(channel);

      final clientMsgId = controller.sendSms('+15551234567', 'SMS from Fake Mac', simSlot: 0);
      expect(clientMsgId, isNotNull);

      final sentSms = channel.sent.last;
      expect(sentSms.type, equals(SmsSendPayload.messageType));
      final payload = SmsSendPayload.fromMap(sentSms.payload);
      expect(payload.address, equals('+15551234567'));
      expect(payload.body, equals('SMS from Fake Mac'));
      expect(payload.clientMessageId, equals(clientMsgId));
    });

    test('dismissNotification and replyNotification send proper envelopes', () async {
      final controller = FakeMacController();
      final channel = MockTransportChannel();
      await controller.attach(channel);

      controller.dismissNotification('pkg|123|null');
      final dismissEnv = channel.sent.last;
      expect(dismissEnv.type, equals(NotificationDismissPayload.messageType));
      expect(dismissEnv.payload['key'], equals('pkg|123|null'));

      controller.replyNotification('pkg|123|null', 'Quick reply message');
      final replyEnv = channel.sent.last;
      expect(replyEnv.type, equals(NotificationActionPayload.messageType));
      expect(replyEnv.payload['key'], equals('pkg|123|null'));
      expect(replyEnv.payload['replyText'], equals('Quick reply message'));
    });

    test('ringPhone sends find.ring and syncClipboard sends clipboard.update', () async {
      final controller = FakeMacController();
      final channel = MockTransportChannel();
      await controller.attach(channel);

      controller.ringPhone();
      final ringEnv = channel.sent.last;
      expect(ringEnv.type, equals('find.ring'));

      controller.syncClipboard('Mac copied text');
      final clipEnv = channel.sent.last;
      expect(clipEnv.type, equals(ClipboardPayload.messageType));
      expect(clipEnv.payload['data'], equals('Mac copied text'));
    });
  });
}
