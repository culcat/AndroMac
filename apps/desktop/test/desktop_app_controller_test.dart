import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:andromac_desktop/desktop_app.dart';

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
  group('DesktopAppController Orchestration', () {
    test('handles peer connection, executes handshake, and updates tray',
        () async {
      final mockPlatform = MockMacOsPlatform();
      final controller = DesktopAppController(
        deviceName: 'Alex MacBook',
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
      expect(helloSent.payload['name'], equals('Alex MacBook'));

      // Deliver phone hello response
      final phoneHello = Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'phone-pixel-8',
          name: 'Pixel 8',
          platform: 'android',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: [
            'clipboard',
            'notifications',
            'sms',
            'device_status',
            'otp'
          ],
        ).toMap(),
      );

      channel.pushMessage(phoneHello);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Controller should have sent hello.ack
      final ackSent = channel.sent.last;
      expect(ackSent.type, equals(HelloAckPayload.messageType));

      expect(controller.isConnected, isTrue);
      expect(
          controller.connectionStatus.state, equals(ConnectionState.connected));
      expect(mockPlatform.trayStatusHistory.last['isConnected'], isTrue);
      expect(
          mockPlatform.trayStatusHistory.last['tooltip'], contains('Pixel 8'));
    });

    test('receives battery status and updates tray badge', () async {
      final mockPlatform = MockMacOsPlatform();
      final controller = DesktopAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      // Deliver phone hello to establish active features
      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'phone-pixel-8',
          name: 'Pixel 8',
          platform: 'android',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: [
            'clipboard',
            'notifications',
            'sms',
            'device_status',
            'otp'
          ],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final batteryEnvelope = Envelope.create(
        type: DeviceStatusPayload.messageType,
        payload: const DeviceStatusPayload(
          batteryLevel: 94,
          isCharging: true,
          networkType: 'wifi',
        ).toMap(),
      );

      channel.pushMessage(batteryEnvelope);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
          mockPlatform.trayStatusHistory.last['batteryBadge'], equals('94%'));
      expect(mockPlatform.trayStatusHistory.last['tooltip'],
          contains('94% (wifi)'));
    });

    test('mirrors incoming notification to native macOS notification system',
        () async {
      final mockPlatform = MockMacOsPlatform();
      final controller = DesktopAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'phone-pixel-8',
          name: 'Pixel 8',
          platform: 'android',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['notifications'],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final notifEnvelope = Envelope.create(
        type: NotificationPostedPayload.messageTypePosted,
        payload: const NotificationPostedPayload(
          key: 'whatsapp|99|null',
          packageName: 'com.whatsapp',
          appName: 'WhatsApp',
          title: 'Mom',
          text: 'Have a great day!',
          postTime: 1760000000000,
          canReply: true,
        ).toMap(),
      );

      channel.pushMessage(notifEnvelope);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(mockPlatform.displayedNotifications.length, equals(1));
      final displayed = mockPlatform.displayedNotifications.first;
      expect(displayed['title'], equals('WhatsApp'));
      expect(displayed['subtitle'], equals('Mom'));
      expect(displayed['body'], equals('Have a great day!'));
      expect(displayed['canReply'], isTrue);
    });

    test('extracts OTP code from SMS, copies to pasteboard, and triggers alert',
        () async {
      final mockPlatform = MockMacOsPlatform();
      final controller = DesktopAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      channel.pushMessage(Envelope.create(
        type: HelloPayload.messageType,
        payload: const HelloPayload(
          deviceId: 'phone-pixel-8',
          name: 'Pixel 8',
          platform: 'android',
          appVersion: '1.0.0',
          protocolVersion: 1,
          capabilities: ['sms', 'otp'],
        ).toMap(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final smsEnvelope = Envelope.create(
        type: SmsReceivedPayload.messageType,
        payload: const SmsReceivedPayload(
          messageId: 'sms-otp-1',
          threadId: 'th-1',
          address: 'T-Bank',
          body: 'Код подтверждения: 839201. Никому не сообщайте.',
          timestamp: 1760000000000,
        ).toMap(),
      );

      channel.pushMessage(smsEnvelope);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Code should be copied directly to macOS pasteboard
      expect(mockPlatform.pasteboardCopies, contains('839201'));
      expect(await mockPlatform.readPasteboard(), equals('839201'));

      // And an OTP notification displayed
      final otpNotification = mockPlatform.displayedNotifications.firstWhere(
        (n) => n['title'] == 'Код подтверждения скопирован',
      );
      expect(otpNotification['body'], contains('839201'));
    });

    test('disconnect cleans up active connection and resets tray', () async {
      final mockPlatform = MockMacOsPlatform();
      final controller = DesktopAppController(platform: mockPlatform);
      final channel = MockTransportChannel();
      await controller.handleConnection(channel);

      expect(controller.isConnected, isTrue);

      await controller.disconnect();

      expect(controller.isConnected, isFalse);
      expect(controller.connectionStatus.state,
          equals(ConnectionState.disconnected));
      expect(mockPlatform.trayStatusHistory.last['isConnected'], isFalse);
    });
  });
}
