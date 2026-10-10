import 'package:test/test.dart';
import 'package:bridge_core/bridge_core.dart';

void main() {
  group('MemoryEncryptedStorage', () {
    late BridgeStorage storage;

    setUp(() {
      storage = MemoryEncryptedStorage();
    });

    group('SMS Storage', () {
      test('saves messages, groups by thread, and performs full-text search',
          () async {
        final sms1 = SmsRecord(
          id: 'sms-1',
          threadId: 'th-alex',
          address: '+79991234567',
          body: 'Привет, как продвигается AndroMac?',
          timestamp: 1000,
        );

        final sms2 = SmsRecord(
          id: 'sms-2',
          threadId: 'th-alex',
          address: '+79991234567',
          body: 'Все отлично, пишем хранилище!',
          timestamp: 2000,
        );

        final sms3 = SmsRecord(
          id: 'sms-3',
          threadId: 'th-bank',
          address: 'T-Bank',
          body: 'Код подтверждения: 981203',
          timestamp: 3000,
        );

        await storage.saveSms(sms1);
        await storage.saveSms(sms2);
        await storage.saveSms(sms3);

        final alexMessages = await storage.getSmsByThread('th-alex');
        expect(alexMessages.length, equals(2));
        expect(alexMessages.first.id, equals('sms-1'));
        expect(alexMessages.last.id, equals('sms-2'));

        final threads = await storage.getAllThreadIds();
        expect(threads, containsAll(['th-alex', 'th-bank']));

        // Search by body content
        final searchBody = await storage.searchSms('AndroMac');
        expect(searchBody.length, equals(1));
        expect(searchBody.first.id, equals('sms-1'));

        // Search by address
        final searchAddress = await storage.searchSms('t-bank');
        expect(searchAddress.length, equals(1));
        expect(searchAddress.first.address, equals('T-Bank'));

        // Delete thread
        await storage.deleteThread('th-bank');
        expect(await storage.getSmsByThread('th-bank'), isEmpty);
      });
    });

    group('Notification Storage', () {
      test('saves, dismisses, and purges notifications older than TTL',
          () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final oldTime = DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch;

        final notifRecent = NotificationRecord(
          key: 'tg|1',
          packageName: 'org.telegram',
          appName: 'Telegram',
          title: 'Dmitry',
          text: 'Check PR',
          postTime: now,
        );

        final notifOld = NotificationRecord(
          key: 'wa|2',
          packageName: 'com.whatsapp',
          appName: 'WhatsApp',
          title: 'Alice',
          text: 'Old notification',
          postTime: oldTime,
        );

        await storage.saveNotification(notifRecent);
        await storage.saveNotification(notifOld);

        var active = await storage.getActiveNotifications();
        expect(active.length, equals(2));

        // Dismiss one notification
        await storage.dismissNotification('tg|1');
        active = await storage.getActiveNotifications();
        expect(active.length, equals(1));
        expect(active.first.key, equals('wa|2'));

        // Purge notifications older than 7 days
        final purged =
            await storage.purgeNotificationsOlderThan(const Duration(days: 7));
        expect(purged, equals(1));

        active = await storage.getActiveNotifications();
        expect(active, isEmpty);
      });
    });

    group('Clipboard Storage', () {
      test('enforces FIFO eviction while preserving pinned items', () async {
        // Fill storage with 25 items (default capacity 20)
        for (var i = 1; i <= 25; i++) {
          final record = ClipboardRecord(
            id: 'clip-$i',
            content: 'Text $i',
            originDeviceId: 'phone-1',
            timestamp: i * 1000,
          );
          await storage.saveClipboard(record);
        }

        var history = await storage.getClipboardHistory(limit: 50);
        // Only 20 items remain due to FIFO capacity cap
        expect(history.length, equals(20));
        // Items 1..5 were evicted
        expect(history.any((c) => c.id == 'clip-1'), isFalse);
        expect(history.any((c) => c.id == 'clip-25'), isTrue);

        // Pin item clip-10
        await storage.pinClipboardItem('clip-10', true);

        // Add 20 more items
        for (var i = 26; i <= 45; i++) {
          final record = ClipboardRecord(
            id: 'clip-$i',
            content: 'Text $i',
            originDeviceId: 'phone-1',
            timestamp: i * 1000,
          );
          await storage.saveClipboard(record);
        }

        history = await storage.getClipboardHistory(limit: 50);
        // Pinned item clip-10 must survive eviction
        expect(history.any((c) => c.id == 'clip-10'), isTrue);
        final pinned = history.firstWhere((c) => c.id == 'clip-10');
        expect(pinned.isPinned, isTrue);

        // Clear clipboard history preserves pinned item
        await storage.clearClipboardHistory();
        history = await storage.getClipboardHistory(limit: 50);
        expect(history.length, equals(1));
        expect(history.first.id, equals('clip-10'));
      });
    });

    group('Device Storage', () {
      test('saves, retrieves, and deletes paired devices', () async {
        final device = DeviceRecord(
          deviceId: 'mac-studio-1',
          name: 'Alex Mac Studio',
          platform: 'macos',
          certificateFingerprint: 'sha256:abc123456789',
          lastSeen: 1760000000000,
        );

        await storage.saveDevice(device);

        final retrieved = await storage.getDevice('mac-studio-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Alex Mac Studio'));
        expect(retrieved.certificateFingerprint, equals('sha256:abc123456789'));

        final all = await storage.getAllDevices();
        expect(all.length, equals(1));

        await storage.deleteDevice('mac-studio-1');
        expect(await storage.getDevice('mac-studio-1'), isNull);
      });
    });
  });
}
