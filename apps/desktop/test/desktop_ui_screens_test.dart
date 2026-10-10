import 'package:test/test.dart';
import 'package:bridge_ui/bridge_ui.dart';
import 'package:andromac_desktop/desktop_app.dart';

void main() {
  group('DesktopMainWindowViewConfig', () {
    test('computes tab labels, notification badges, and unread SMS counters',
        () {
      final diagnostics = DiagnosticsChecklistConfig(items: const [
        DiagnosticsItemConfig(
          id: 'lan',
          title: 'Wi-Fi',
          description: 'Connected',
          status: 'ok',
        ),
      ]);

      final now = DateTime(2026, 10, 10, 16, 0).millisecondsSinceEpoch;

      final view = DesktopMainWindowViewConfig(
        activeTab: DesktopTab.messages,
        isConnected: true,
        peerDeviceName: 'Pixel 8 Pro',
        batteryLevel: 91,
        isCharging: true,
        diagnostics: diagnostics,
        notifications: [
          NotificationTileConfig(
            key: 'tg|1',
            packageName: 'org.telegram',
            appName: 'Telegram',
            title: 'Boss',
            text: 'Need review',
            postTime: now,
          ),
          NotificationTileConfig(
            key: 'wa|2',
            packageName: 'com.whatsapp',
            appName: 'WhatsApp',
            title: 'Mom',
            text: 'Call me',
            postTime: now,
            isDismissed: true,
          ),
        ],
        conversations: [
          SmsConversationTileConfig(
            threadId: 'th-1',
            phoneNumber: '+123456789',
            lastMessageSnippet: 'Hi',
            unreadCount: 2,
            lastTimestamp: now,
          ),
          SmsConversationTileConfig(
            threadId: 'th-2',
            phoneNumber: '+987654321',
            lastMessageSnippet: 'Done',
            unreadCount: 1,
            lastTimestamp: now,
          ),
        ],
      );

      // Verify notification counts (1 active, 1 dismissed)
      expect(view.activeNotificationsCount, equals(1));
      expect(view.tabLabel(DesktopTab.notifications), contains('(1)'));

      // Verify total unread SMS count (2 + 1 = 3)
      expect(view.totalUnreadSmsCount, equals(3));
      expect(view.tabLabel(DesktopTab.messages), contains('(3)'));

      // Verify window title formatting
      expect(view.windowTitle, contains('Pixel 8 Pro'));
      expect(view.windowTitle, contains('⚡ 91%'));

      // Verify peer status card derivation
      expect(view.peerStatusCard.deviceName, equals('Pixel 8 Pro'));
      expect(view.peerStatusCard.batteryLevel, equals(91));
      expect(view.peerStatusCard.isCharging, isTrue);
    });

    test('supports bilingual localization switching (ru / en)', () {
      final diagnostics = DiagnosticsChecklistConfig(items: const []);

      final viewRu = DesktopMainWindowViewConfig(
        isConnected: false,
        diagnostics: diagnostics,
        currentLocale: BridgeLocale.ru,
      );
      expect(viewRu.windowTitle, contains('Отключено'));
      expect(viewRu.tabLabel(DesktopTab.clipboard), contains('Буфер обмена'));

      final viewEn = viewRu.copyWith(currentLocale: BridgeLocale.en);
      expect(viewEn.windowTitle, contains('Disconnected'));
      expect(viewEn.tabLabel(DesktopTab.clipboard), contains('Clipboard'));
    });
  });

  group('DesktopPopoverViewConfig', () {
    test('formats header text and limits top notifications to 3 items', () {
      final now = DateTime(2026, 10, 10, 16, 0).millisecondsSinceEpoch;

      final notifs = List.generate(
        5,
        (i) => NotificationTileConfig(
          key: 'notif-$i',
          packageName: 'com.app.$i',
          appName: 'App $i',
          title: 'Title $i',
          text: 'Text $i',
          postTime: now,
        ),
      );

      final popover = DesktopPopoverViewConfig(
        isConnected: true,
        peerDeviceName: 'Samsung Galaxy S24',
        batteryLevel: 65,
        isCharging: false,
        recentNotifications: notifs,
      );

      expect(popover.headerText, contains('Samsung Galaxy S24'));
      expect(popover.headerText, contains('65%'));
      expect(popover.topNotifications.length, equals(3));
    });
  });
}
