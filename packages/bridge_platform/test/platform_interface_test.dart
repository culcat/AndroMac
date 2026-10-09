import 'package:test/test.dart';
import 'package:bridge_platform/bridge_platform.dart';

void main() {
  group('AndroidBridgePlatform & MockAndroidPlatform', () {
    test('captures native service calls and triggers callbacks', () async {
      final platform = MockAndroidPlatform();

      expect(platform.isForegroundServiceRunning, isFalse);
      await platform.startForegroundService();
      expect(platform.isForegroundServiceRunning, isTrue);

      await platform.sendSms(
        address: '+15551234567',
        body: 'Native test SMS',
        simSlot: 1,
        clientMessageId: 'pigeon-msg-1',
      );
      expect(platform.sentSmsList.length, equals(1));
      expect(platform.sentSmsList.first['address'], equals('+15551234567'));
      expect(platform.sentSmsList.first['simSlot'], equals(1));

      await platform.copyToClipboard('Copied natively');
      expect(platform.copiedClipboardItems, contains('Copied natively'));

      // Test callbacks
      Map<String, dynamic>? receivedNotif;
      platform.registerCallbacks(
        onNotificationPosted: (n) => receivedNotif = n,
        onNotificationDismissed: (_) {},
        onSmsReceived: (_) {},
        onClipboardCaptured: (_) {},
        onBatteryChanged: (_, __) {},
      );

      platform.simulateNotificationPosted({'key': 'test|1', 'title': 'Test'});
      expect(receivedNotif, isNotNull);
      expect(receivedNotif!['title'], equals('Test'));
    });
  });

  group('MacOsBridgePlatform & MockMacOsPlatform', () {
    test('captures notifications, tray updates, and pasteboard changes', () async {
      final platform = MockMacOsPlatform();

      await platform.showNotification(
        identifier: 'notif-1',
        title: 'Mac Alert',
        body: 'Battery low',
      );
      expect(platform.displayedNotifications.length, equals(1));
      expect(platform.displayedNotifications.first['title'], equals('Mac Alert'));

      await platform.removeNotification('notif-1');
      expect(platform.displayedNotifications, isEmpty);
      expect(platform.removedNotificationIds, contains('notif-1'));

      await platform.updateTray(
        tooltip: 'AndroMac Connected',
        isConnected: true,
        batteryBadge: '95%',
      );
      expect(platform.trayStatusHistory.length, equals(1));
      expect(platform.trayStatusHistory.first['isConnected'], isTrue);
      expect(platform.trayStatusHistory.first['batteryBadge'], equals('95%'));

      await platform.copyToPasteboard('Pasted on Mac');
      expect(platform.pasteboardCopies, contains('Pasted on Mac'));
      expect(await platform.readPasteboard(), equals('Pasted on Mac'));
      expect(await platform.getPasteboardChangeCount(), equals(1));

      // Test callbacks
      String? actionIdReceived;
      String? replyTextReceived;
      platform.registerCallbacks(
        onNotificationAction: (id, action, reply) {
          actionIdReceived = action;
          replyTextReceived = reply;
        },
        onNotificationDismissed: (_) {},
        onSystemSleep: () {},
        onSystemWake: () {},
        onPasteboardChanged: (_) {},
      );

      platform.simulateNotificationAction('notif-1', 'reply_btn', 'Great news!');
      expect(actionIdReceived, equals('reply_btn'));
      expect(replyTextReceived, equals('Great news!'));
    });
  });
}
