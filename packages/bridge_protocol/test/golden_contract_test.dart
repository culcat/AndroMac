import 'dart:convert';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';

/// Golden contract schema verification ensuring strict cross-platform wire compatibility
/// between Dart, Kotlin (Android), and Swift (macOS) according to bridge-development-plan.md §5.5.
void main() {
  group('Golden Wire Contract Schemas', () {
    test('Envelope wire envelope complies with canonical v1 schema', () {
      const canonicalJson = '''
      {
        "v": 1,
        "id": "01ARZ3NDEKTSV4RRFFQ69G5FAV",
        "type": "ping",
        "ts": 1760000000000,
        "ref": "01ARZ3NDEKTSV4RRFFQ69G5FA0",
        "payload": {
          "timestamp": 1760000000000
        }
      }
      ''';

      final envelope = Envelope.decode(canonicalJson);

      expect(envelope.v, equals(1));
      expect(envelope.id, equals('01ARZ3NDEKTSV4RRFFQ69G5FAV'));
      expect(envelope.type, equals('ping'));
      expect(envelope.ts, equals(1760000000000));
      expect(envelope.ref, equals('01ARZ3NDEKTSV4RRFFQ69G5FA0'));
      expect(envelope.payload['timestamp'], equals(1760000000000));

      final reEncoded = jsonDecode(envelope.encode());
      expect(reEncoded['v'], equals(1));
      expect(reEncoded['id'], equals('01ARZ3NDEKTSV4RRFFQ69G5FAV'));
      expect(reEncoded['type'], equals('ping'));
      expect(reEncoded['ts'], equals(1760000000000));
      expect(reEncoded['ref'], equals('01ARZ3NDEKTSV4RRFFQ69G5FA0'));
      expect(reEncoded['payload']['timestamp'], equals(1760000000000));
    });

    test('hello handshake payload golden contract', () {
      const canonicalHelloJson = '''
      {
        "deviceId": "mac-uuid-001",
        "name": "Alex MacBook Pro",
        "platform": "macos",
        "appVersion": "1.0.0",
        "protocolVersion": 1,
        "capabilities": [
          "clipboard",
          "notifications",
          "sms",
          "device_status",
          "otp",
          "file_transfer",
          "remote_control"
        ]
      }
      ''';

      final map = jsonDecode(canonicalHelloJson) as Map<String, dynamic>;
      final payload = HelloPayload.fromMap(map);

      expect(payload.deviceId, equals('mac-uuid-001'));
      expect(payload.name, equals('Alex MacBook Pro'));
      expect(payload.platform, equals('macos'));
      expect(payload.appVersion, equals('1.0.0'));
      expect(payload.protocolVersion, equals(1));
      expect(payload.capabilities.length, equals(7));
      expect(payload.capabilities, contains('remote_control'));

      final encodedMap = payload.toMap();
      expect(encodedMap['deviceId'], equals('mac-uuid-001'));
      expect(encodedMap['platform'], equals('macos'));
      expect(encodedMap['capabilities'], contains('clipboard'));
    });

    test('hello.ack handshake acknowledgement golden contract', () {
      const canonicalAckJson = '''
      {
        "accepted": true,
        "deviceId": "phone-pixel-001",
        "agreedCapabilities": [
          "clipboard",
          "notifications",
          "sms"
        ]
      }
      ''';

      final map = jsonDecode(canonicalAckJson) as Map<String, dynamic>;
      final payload = HelloAckPayload.fromMap(map);

      expect(payload.accepted, isTrue);
      expect(payload.deviceId, equals('phone-pixel-001'));
      expect(payload.agreedCapabilities, equals(['clipboard', 'notifications', 'sms']));
    });

    test('clipboard.update payload golden contract', () {
      const canonicalClipJson = '''
      {
        "content": "Secret recovery phrase or URL",
        "mimeType": "text/plain",
        "originDeviceId": "phone-pixel-001",
        "hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        "seq": 142
      }
      ''';

      final map = jsonDecode(canonicalClipJson) as Map<String, dynamic>;
      final payload = ClipboardPayload.fromMap(map);

      expect(payload.content, equals('Secret recovery phrase or URL'));
      expect(payload.mimeType, equals('text/plain'));
      expect(payload.originDeviceId, equals('phone-pixel-001'));
      expect(payload.hash, equals('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'));
      expect(payload.seq, equals(142));
    });

    test('device.status telemetry payload golden contract', () {
      const canonicalStatusJson = '''
      {
        "batteryLevel": 88,
        "isCharging": true,
        "networkType": "wifi",
        "signalStrength": 4,
        "isDndActive": false
      }
      ''';

      final map = jsonDecode(canonicalStatusJson) as Map<String, dynamic>;
      final payload = DeviceStatusPayload.fromMap(map);

      expect(payload.batteryLevel, equals(88));
      expect(payload.isCharging, isTrue);
      expect(payload.networkType, equals('wifi'));
      expect(payload.signalStrength, equals(4));
      expect(payload.isDndActive, isFalse);
    });

    test('notif.posted notification mirroring payload golden contract', () {
      const canonicalNotifJson = '''
      {
        "key": "com.telegram.messenger|1002|chat",
        "packageName": "org.telegram.messenger",
        "appName": "Telegram",
        "title": "Dmitry",
        "text": "Code review ready for AndroMac",
        "postTime": 1760000500000,
        "canReply": true,
        "actions": [
          {
            "actionId": "reply_inline",
            "title": "Ответить",
            "isQuickReply": true
          }
        ]
      }
      ''';

      final map = jsonDecode(canonicalNotifJson) as Map<String, dynamic>;
      final payload = NotificationPostedPayload.fromMap(map);

      expect(payload.key, equals('com.telegram.messenger|1002|chat'));
      expect(payload.packageName, equals('org.telegram.messenger'));
      expect(payload.appName, equals('Telegram'));
      expect(payload.title, equals('Dmitry'));
      expect(payload.text, equals('Code review ready for AndroMac'));
      expect(payload.postTime, equals(1760000500000));
      expect(payload.canReply, isTrue);
      expect(payload.actions.length, equals(1));
      expect(payload.actions.first.actionId, equals('reply_inline'));
      expect(payload.actions.first.title, equals('Ответить'));
      expect(payload.actions.first.isQuickReply, isTrue);
    });

    test('sms.received and sms.send payloads golden contract', () {
      const canonicalSmsRecv = '''
      {
        "messageId": "sms-10029",
        "threadId": "th-99",
        "address": "+79991234567",
        "body": "Код авторизации: 591024",
        "timestamp": 1760000800000
      }
      ''';

      final recvMap = jsonDecode(canonicalSmsRecv) as Map<String, dynamic>;
      final recvPayload = SmsReceivedPayload.fromMap(recvMap);

      expect(recvPayload.messageId, equals('sms-10029'));
      expect(recvPayload.address, equals('+79991234567'));
      expect(recvPayload.body, contains('591024'));

      const canonicalSmsSend = '''
      {
        "clientMessageId": "cli-msg-007",
        "address": "+79991234567",
        "body": "Approved!",
        "simSlot": 0
      }
      ''';

      final sendMap = jsonDecode(canonicalSmsSend) as Map<String, dynamic>;
      final sendPayload = SmsSendPayload.fromMap(sendMap);

      expect(sendPayload.clientMessageId, equals('cli-msg-007'));
      expect(sendPayload.address, equals('+79991234567'));
      expect(sendPayload.body, equals('Approved!'));
      expect(sendPayload.simSlot, equals(0));
    });

    test('error payload golden contract', () {
      const canonicalErrorJson = '''
      {
        "code": "AUTH_FAILED",
        "message": "Certificate fingerprint mismatch",
        "details": {
          "expected": "sha256:abc",
          "actual": "sha256:def"
        }
      }
      ''';

      final map = jsonDecode(canonicalErrorJson) as Map<String, dynamic>;
      final payload = ErrorPayload.fromMap(map);

      expect(payload.code, equals('AUTH_FAILED'));
      expect(payload.message, equals('Certificate fingerprint mismatch'));
      expect(payload.details?['expected'], equals('sha256:abc'));
    });
  });
}
