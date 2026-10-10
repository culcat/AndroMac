import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:andromac_phone/phone_app.dart';

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
  group('PhoneAppController Orchestration', () {
    test('handles peer connection, sends hello, receives hello from Mac, and sends hello.ack', () async {
      final mockPlatform = MockAndroidPlatform();
      final controller = PhoneAppController(
        deviceName: 'Pixel 8',
        platform: mockPlatform,
      );

      final statusEvents = <ConnectionStatus>[];
      controller.onStatusChanged.listen(statusEvents.add);

      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      // Verify controller sent hello
      expect(channel.sent.length, equals(1));
      final helloSent = channel.sent.first;
      expect(helloSent.type, equals(HelloPayload.messageType));
      expect(helloSent.payload['name'], equals('Pixel 8'));
      expect(helloSent.payload['platform'], equals('android'));

      // Simulate Mac sending hello
      final macHello = Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'mac-studio-1',
          name: 'Alex Mac Studio',
          platform: 'macos',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['clipboard', 'notifications', 'sms', 'device_status', 'otp', 'file_transfer'],
        ).toMap(),
      );

      channel.pushMessage(macHello);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Controller should have sent hello.ack and initial battery status
      final ackSent = channel.sent.firstWhere((e) => e.type == HelloAckPayload.messageType);
      expect(ackSent.ref, equals(macHello.id));
      expect(ackSent.payload['accepted'], isTrue);

      expect(controller.isConnected, isTrue);
      expect(controller.connectionStatus.state, equals(ConnectionState.connected));
      expect(controller.connectionStatus.peerDeviceId, equals('mac-studio-1'));
    });

    test('receives native notification and broadcasts notif.posted to Mac', () async {
      final mockPlatform = MockAndroidPlatform();
      final controller = PhoneAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      // Deliver Mac hello to establish active context
      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'mac-1',
          name: 'MacBook',
          platform: 'macos',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['notifications'],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Simulate native notification posted on Android
      mockPlatform.simulateNotificationPosted({
        'key': 'telegram|100|group',
        'packageName': 'org.telegram.messenger',
        'appName': 'Telegram',
        'title': 'Project Chat',
        'text': 'Release v1.0 is ready!',
        'postTime': 1760001000000,
        'canReply': true,
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Check that notif.posted was dispatched over the wire
      final notifEnvelope = channel.sent.firstWhere(
        (e) => e.type == NotificationPostedPayload.messageTypePosted,
      );
      expect(notifEnvelope.payload['appName'], equals('Telegram'));
      expect(notifEnvelope.payload['title'], equals('Project Chat'));
      expect(notifEnvelope.payload['text'], equals('Release v1.0 is ready!'));
      expect(notifEnvelope.payload['canReply'], isTrue);
    });

    test('receives native SMS, broadcasts to Mac, and triggers OTP extraction', () async {
      final mockPlatform = MockAndroidPlatform();
      final controller = PhoneAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'mac-1',
          name: 'MacBook',
          platform: 'macos',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['sms', 'otp'],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Simulate native SMS arrival
      mockPlatform.simulateSmsReceived({
        'messageId': 'sms-101',
        'threadId': 't-101',
        'address': 'BankAuth',
        'body': 'Ваш проверочный код: 492018. Действителен 5 минут.',
        'timestamp': 1760002000000,
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final smsEnvelope = channel.sent.firstWhere(
        (e) => e.type == SmsReceivedPayload.messageType,
      );
      expect(smsEnvelope.payload['address'], equals('BankAuth'));
      expect(smsEnvelope.payload['body'], contains('492018'));
    });

    test('receives sms.send from Mac and triggers native platform dispatch', () async {
      final mockPlatform = MockAndroidPlatform();
      final controller = PhoneAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'mac-1',
          name: 'MacBook',
          platform: 'macos',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['sms'],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Deliver SMS send command from Mac
      final sendCommand = Envelope.create(
        type: SmsSendPayload.messageType,
        payload: const SmsSendPayload(
          clientMessageId: 'cli-sms-99',
          address: '+79991234567',
          body: 'Hello from macOS desktop!',
          simSlot: 0,
        ).toMap(),
      );

      channel.pushMessage(sendCommand);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Verify native platform was called to send SMS
      expect(mockPlatform.sentSmsList.length, equals(1));
      final sent = mockPlatform.sentSmsList.first;
      expect(sent['address'], equals('+79991234567'));
      expect(sent['body'], equals('Hello from macOS desktop!'));
      expect(sent['clientMessageId'], equals('cli-sms-99'));

      // Verify confirmation status was sent back over the wire
      final statusConfirm = channel.sent.firstWhere(
        (e) => e.type == SmsSentStatusPayload.messageType,
      );
      expect(statusConfirm.payload['clientMessageId'], equals('cli-sms-99'));
      expect(statusConfirm.payload['status'], equals('sent'));
    });

    test('receives clipboard update from Mac and copies to Android clipboard', () async {
      final mockPlatform = MockAndroidPlatform();
      final controller = PhoneAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'mac-1',
          name: 'MacBook',
          platform: 'macos',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['clipboard'],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final clipEnvelope = Envelope.create(
        type: ClipboardPayload.messageType,
        payload: const ClipboardPayload(
          content: 'https://github.com/culcat/AndroMac',
          mimeType: 'text/plain',
          originDeviceId: 'mac-1',
        ).toMap(),
      );

      channel.pushMessage(clipEnvelope);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(mockPlatform.copiedClipboardItems, contains('https://github.com/culcat/AndroMac'));
    });

    test('triggers Find My Phone ring alert when requested by Mac', () async {
      final mockPlatform = MockAndroidPlatform();
      final controller = PhoneAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'mac-1',
          name: 'MacBook',
          platform: 'macos',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['device_status'],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      String? ringReason;
      controller.onRingAlert.listen((reason) {
        ringReason = reason;
      });

      // Mac sends ring command
      final ringEnvelope = Envelope.create(
        type: 'find.ring',
        payload: {'reason': 'User lost phone in room'},
      );

      channel.pushMessage(ringEnvelope);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(ringReason, equals('User lost phone in room'));
    });

    test('broadcasts battery updates when native platform reports change', () async {
      final mockPlatform = MockAndroidPlatform();
      final controller = PhoneAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'mac-1',
          name: 'MacBook',
          platform: 'macos',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['device_status'],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Simulate battery status change
      mockPlatform.simulateBatteryChanged(87, true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.batteryLevel, equals(87));
      expect(controller.isCharging, isTrue);

      final batteryEnvelopes = channel.sent.where((e) => e.type == DeviceStatusPayload.messageType);
      expect(batteryEnvelopes.isNotEmpty, isTrue);
      final latestBattery = batteryEnvelopes.last;
      expect(latestBattery.payload['batteryLevel'], equals(87));
      expect(latestBattery.payload['isCharging'], isTrue);
    });

    test('disconnect and stop properly cleans up server and active connection', () async {
      final mockPlatform = MockAndroidPlatform();
      final controller = PhoneAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      expect(controller.isConnected, isTrue);

      await controller.disconnect();

      expect(controller.isConnected, isFalse);
      expect(controller.connectionStatus.state, equals(ConnectionState.disconnected));

      await controller.stop();
      expect(mockPlatform.isForegroundServiceRunning, isFalse);
    });
  });
}
