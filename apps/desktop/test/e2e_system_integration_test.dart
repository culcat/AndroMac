import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:andromac_desktop/desktop_app.dart';
import 'package:andromac_phone/phone_app.dart';

/// Bidirectional in-memory piped channel pair simulating a local network mTLS WebSocket.
class PipedTransportChannelPair {
  final _macToPhone = StreamController<Envelope>.broadcast();
  final _phoneToMac = StreamController<Envelope>.broadcast();

  late final TransportChannel macChannel;
  late final TransportChannel phoneChannel;

  PipedTransportChannelPair() {
    macChannel = _PipedChannel(_phoneToMac.stream, _macToPhone);
    phoneChannel = _PipedChannel(_macToPhone.stream, _phoneToMac);
  }

  void close() {
    _macToPhone.close();
    _phoneToMac.close();
  }
}

class _PipedChannel implements TransportChannel {
  final Stream<Envelope> _incoming;
  final StreamController<Envelope> _outgoing;
  bool _open = true;

  _PipedChannel(this._incoming, this._outgoing);

  @override
  Stream<Envelope> get incoming => _incoming;

  @override
  bool get isOpen => _open;

  @override
  void send(Envelope envelope) {
    if (_open && !_outgoing.isClosed) {
      _outgoing.add(envelope);
    }
  }

  @override
  Future<void> close() async {
    _open = false;
  }
}

void main() {
  group('End-to-End System Integration: Desktop Mac <-> Phone Android', () {
    test(
        'full system integration: handshake, battery, notifications, SMS, OTP auto-copy, clipboard sync, and teardown',
        () async {
      final macPlatform = MockMacOsPlatform();
      final phonePlatform = MockAndroidPlatform();

      final macController = DesktopAppController(
        deviceName: 'Alex MacBook Pro',
        platform: macPlatform,
      );

      final phoneController = PhoneAppController(
        deviceName: 'Google Pixel 8 Pro',
        platform: phonePlatform,
      );

      final pair = PipedTransportChannelPair();

      // 1. Establish P2P link and execute handshake
      final macHandleFuture = macController.handleConnection(pair.macChannel);
      final phoneHandleFuture =
          phoneController.handleConnection(pair.phoneChannel);

      await Future.wait([macHandleFuture, phoneHandleFuture]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(macController.isConnected, isTrue);
      expect(phoneController.isConnected, isTrue);
      expect(macController.connectionStatus.state,
          equals(ConnectionState.connected));
      expect(phoneController.connectionStatus.state,
          equals(ConnectionState.connected));

      // Mac menu bar tray reflects connected phone
      expect(macPlatform.trayStatusHistory.any((s) => s['isConnected'] == true),
          isTrue);
      expect(
          macPlatform.trayStatusHistory.any(
              (s) => (s['tooltip'] as String).contains('Google Pixel 8 Pro')),
          isTrue);

      // 2. Battery telemetry update
      phonePlatform.simulateBatteryChanged(88, true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(phoneController.batteryLevel, equals(88));
      expect(phoneController.isCharging, isTrue);
      expect(macPlatform.trayStatusHistory.last['batteryBadge'], equals('88%'));
      expect(macPlatform.trayStatusHistory.last['tooltip'], contains('88%'));

      // 3. Notification Mirroring & Actionable Reply Loop
      phonePlatform.simulateNotificationPosted({
        'key': 'telegram|4001|dm',
        'packageName': 'org.telegram.messenger',
        'appName': 'Telegram',
        'title': 'Elena',
        'text': 'Let us sync the release branch',
        'postTime': 1760000000000,
        'canReply': true,
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Notification displayed on macOS
      expect(macPlatform.displayedNotifications.length, equals(1));
      final displayedNotif = macPlatform.displayedNotifications.first;
      expect(displayedNotif['title'], equals('Telegram'));
      expect(displayedNotif['subtitle'], equals('Elena'));
      expect(displayedNotif['body'], equals('Let us sync the release branch'));
      expect(displayedNotif['canReply'], isTrue);

      // User replies from macOS Notification Center
      macPlatform.simulateNotificationAction(
          'telegram|4001|dm', 'reply', 'On my way!');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 4. Outbound SMS Dispatch from Mac & Confirmation Loop
      final clientMsgId = macController.sms.sendSms(
        '+79991234567',
        'Meeting confirmed for 15:00',
        simSlot: 0,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Phone native platform received and sent SMS
      expect(phonePlatform.sentSmsList.length, equals(1));
      final sentSms = phonePlatform.sentSmsList.first;
      expect(sentSms['address'], equals('+79991234567'));
      expect(sentSms['body'], equals('Meeting confirmed for 15:00'));
      expect(sentSms['clientMessageId'], equals(clientMsgId));

      // Delivery status confirmed on Mac
      final macSmsItem = macController.sms.store.getMessage(clientMsgId!);
      expect(macSmsItem?.status, equals(SmsDeliveryStatus.delivered));

      // 5. 2FA / OTP Extraction from Banking SMS & Auto-Copy to Pasteboard
      phonePlatform.simulateSmsReceived({
        'messageId': 'bank-sms-1',
        'threadId': 't-bank',
        'address': 'T-Bank',
        'body': 'Код подтверждения: 839102. Никому не сообщайте.',
        'timestamp': 1760001000000,
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verification code auto-copied to macOS pasteboard
      expect(macPlatform.pasteboardCopies, contains('839102'));
      expect(await macPlatform.readPasteboard(), equals('839102'));

      // Native OTP alert banner displayed on Mac
      final otpBanner = macPlatform.displayedNotifications.firstWhere(
        (n) => n['title'] == 'Код подтверждения скопирован',
      );
      expect(otpBanner['body'], contains('839102'));

      // 6. Bidirectional Clipboard Sync
      // Mac -> Phone
      macPlatform.simulatePasteboardChange(
          'https://github.com/culcat/AndroMac/releases');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(phonePlatform.copiedClipboardItems,
          contains('https://github.com/culcat/AndroMac/releases'));

      // Phone -> Mac (triggered via Quick Settings tile or Share sheet)
      phonePlatform.simulateClipboardCaptured('Copied from Android Phone');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
          macPlatform.pasteboardCopies, contains('Copied from Android Phone'));

      // 7. Graceful Disconnect & Teardown
      await macController.disconnect();
      await phoneController.disconnect();

      expect(macController.isConnected, isFalse);
      expect(phoneController.isConnected, isFalse);
      expect(macPlatform.trayStatusHistory.last['isConnected'], isFalse);

      pair.close();
    });
  });
}
