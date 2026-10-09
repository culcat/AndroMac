import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:fake_phone/fake_phone.dart';

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
  group('FakePhoneDevice', () {
    test('attach sends hello handshake message', () async {
      final device = FakePhoneDevice(name: 'Test Android');
      final channel = MockTransportChannel();

      await device.attach(channel);

      expect(channel.sent.length, equals(1));
      final hello = channel.sent.first;
      expect(hello.type, equals(HelloPayload.messageType));
      expect(hello.payload['name'], equals('Test Android'));
      expect(hello.payload['platform'], equals('android'));
    });

    test('sendBatteryStatus sends device.status envelope', () async {
      final device = FakePhoneDevice();
      final channel = MockTransportChannel();
      await device.attach(channel);

      device.sendBatteryStatus(batteryLevel: 80, isCharging: false);

      expect(channel.sent.length, equals(2));
      final status = channel.sent.last;
      expect(status.type, equals(DeviceStatusPayload.messageType));
      expect(status.payload['batteryLevel'], equals(80));
      expect(status.payload['isCharging'], isFalse);
    });

    test('sendNotification and sendSms generate correct events', () async {
      final device = FakePhoneDevice();
      final channel = MockTransportChannel();
      await device.attach(channel);

      device.sendNotification(
        appName: 'Telegram',
        packageName: 'org.telegram.messenger',
        title: 'Alice',
        text: 'Testing bridge notification',
      );

      final notif = channel.sent.last;
      expect(notif.type, equals(NotificationPostedPayload.messageTypePosted));
      expect(notif.payload['appName'], equals('Telegram'));
      expect(notif.payload['title'], equals('Alice'));

      device.sendSms(address: '+123456789', body: 'Test SMS body');

      final sms = channel.sent.last;
      expect(sms.type, equals(SmsReceivedPayload.messageType));
      expect(sms.payload['address'], equals('+123456789'));
      expect(sms.payload['body'], equals('Test SMS body'));
    });

    test('auto-confirms sms.send commands from Mac', () async {
      final device = FakePhoneDevice();
      final channel = MockTransportChannel();
      await device.attach(channel);

      final macSmsCommand = Envelope.create(
        type: SmsSendPayload.messageType,
        payload: const SmsSendPayload(
          address: '+987654321',
          body: 'Hello from Mac',
          clientMessageId: 'mac-req-1',
        ).toMap(),
      );

      channel.pushMessage(macSmsCommand);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final ack = channel.sent.last;
      expect(ack.type, equals(SmsSentStatusPayload.messageType));
      expect(ack.payload['clientMessageId'], equals('mac-req-1'));
      expect(ack.payload['success'], isTrue);
    });
  });
}
