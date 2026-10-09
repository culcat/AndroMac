import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';

void main() {
  group('Message Payloads Serialization', () {
    test('HelloPayload and HelloAckPayload', () {
      final hello = HelloPayload(
        deviceId: 'dev-mac-1',
        name: 'Alex MacBook Pro',
        platform: 'macos',
        appVersion: '1.0.0',
        protocolVersion: 1,
        capabilities: ['clipboard', 'notifications', 'sms'],
      );

      final map = hello.toMap();
      final fromMap = HelloPayload.fromMap(map);

      expect(fromMap.deviceId, equals('dev-mac-1'));
      expect(fromMap.name, equals('Alex MacBook Pro'));
      expect(fromMap.platform, equals('macos'));
      expect(fromMap.capabilities, contains('clipboard'));

      final ack = HelloAckPayload(
        accepted: true,
        deviceId: 'dev-phone-1',
        agreedCapabilities: ['clipboard', 'notifications'],
      );
      final ackMap = ack.toMap();
      final ackFromMap = HelloAckPayload.fromMap(ackMap);

      expect(ackFromMap.accepted, isTrue);
      expect(ackFromMap.deviceId, equals('dev-phone-1'));
      expect(ackFromMap.agreedCapabilities.length, equals(2));
    });

    test('PingPayload and PongPayload', () {
      final ping = PingPayload(timestamp: 1000);
      expect(PingPayload.fromMap(ping.toMap()).timestamp, equals(1000));

      final pong = PongPayload(timestamp: 1015, receivedTimestamp: 1000);
      final pongFrom = PongPayload.fromMap(pong.toMap());
      expect(pongFrom.timestamp, equals(1015));
      expect(pongFrom.receivedTimestamp, equals(1000));
    });

    test('ClipboardPayload', () {
      final clip = ClipboardPayload(
        mime: 'text/plain',
        data: 'Secret link',
        hash: 'sha256-test',
        origin: 'dev-phone-1',
        seq: 42,
      );

      final fromMap = ClipboardPayload.fromMap(clip.toMap());
      expect(fromMap.mime, equals('text/plain'));
      expect(fromMap.data, equals('Secret link'));
      expect(fromMap.hash, equals('sha256-test'));
      expect(fromMap.seq, equals(42));
    });

    test('DeviceStatusPayload', () {
      final status = DeviceStatusPayload(
        batteryLevel: 85,
        isCharging: true,
        networkType: 'wifi',
        wifiSignalStrength: 4,
        isDndActive: false,
      );

      final fromMap = DeviceStatusPayload.fromMap(status.toMap());
      expect(fromMap.batteryLevel, equals(85));
      expect(fromMap.isCharging, isTrue);
      expect(fromMap.networkType, equals('wifi'));
      expect(fromMap.wifiSignalStrength, equals(4));
    });

    test('NotificationPostedPayload and Actions', () {
      final notif = NotificationPostedPayload(
        key: 'com.whatsapp|101|null',
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        title: 'Alice',
        text: 'Are we still meeting today?',
        postTime: 1760000000000,
        canReply: true,
        actions: [
          NotificationAction(
            actionId: 'action_reply',
            title: 'Reply',
            isQuickReply: true,
          ),
        ],
      );

      final fromMap = NotificationPostedPayload.fromMap(notif.toMap());
      expect(fromMap.key, equals('com.whatsapp|101|null'));
      expect(fromMap.appName, equals('WhatsApp'));
      expect(fromMap.canReply, isTrue);
      expect(fromMap.actions.length, equals(1));
      expect(fromMap.actions.first.isQuickReply, isTrue);
    });

    test('Sms payloads', () {
      final smsRecv = SmsReceivedPayload(
        messageId: 'msg-1',
        threadId: 'th-1',
        address: '+1234567890',
        body: 'Your verification code is 492011',
        timestamp: 1760000000000,
      );
      final recvFrom = SmsReceivedPayload.fromMap(smsRecv.toMap());
      expect(recvFrom.address, equals('+1234567890'));
      expect(recvFrom.body, contains('492011'));

      final smsSend = SmsSendPayload(
        address: '+1234567890',
        body: 'OK!',
        clientMessageId: 'client-1',
      );
      final sendFrom = SmsSendPayload.fromMap(smsSend.toMap());
      expect(sendFrom.clientMessageId, equals('client-1'));

      final smsStatus = SmsSentStatusPayload(
        clientMessageId: 'client-1',
        success: true,
      );
      final statusFrom = SmsSentStatusPayload.fromMap(smsStatus.toMap());
      expect(statusFrom.success, isTrue);
    });

    test('Pairing payloads', () {
      final pairReq = PairRequestPayload(
        deviceId: 'mac-id',
        deviceName: 'MacBook',
        publicKeyFingerprint: 'sha256:abc',
        pairingCode: '123456',
      );
      expect(PairRequestPayload.fromMap(pairReq.toMap()).pairingCode, equals('123456'));

      final pairAccept = PairAcceptPayload(
        deviceId: 'phone-id',
        deviceName: 'Pixel 8',
        sasCode: '987654',
        publicKeyFingerprint: 'sha256:def',
      );
      expect(PairAcceptPayload.fromMap(pairAccept.toMap()).sasCode, equals('987654'));
    });
  });
}
