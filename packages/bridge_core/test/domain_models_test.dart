import 'package:test/test.dart';
import 'package:bridge_core/bridge_core.dart';

void main() {
  group('Domain Models and EventBus', () {
    test('Device and PeerDevice serialization and equality', () {
      final dev = Device(
        id: 'dev-1',
        name: 'Pixel 8',
        platform: DevicePlatform.android,
        appVersion: '1.0.0',
      );

      final map = dev.toMap();
      final fromMap = Device.fromMap(map);

      expect(fromMap.id, equals('dev-1'));
      expect(fromMap.name, equals('Pixel 8'));
      expect(fromMap.platform, equals(DevicePlatform.android));
      expect(fromMap, equals(dev));

      final peer = PeerDevice(
        device: dev,
        certificateFingerprint: 'aabbccdd',
        pairedAt: DateTime.now(),
        enabledFeatures: {'clipboard', 'sms'},
        isOnline: true,
      );

      expect(peer.isOnline, isTrue);
      expect(peer.enabledFeatures, contains('clipboard'));

      final offlinePeer = peer.copyWith(isOnline: false);
      expect(offlinePeer.isOnline, isFalse);
    });

    test('NotificationItem and actions', () {
      final item = NotificationItem(
        key: 'com.telegram|1|tag',
        packageName: 'com.telegram',
        appName: 'Telegram',
        title: 'Bob',
        text: 'Hey there!',
        postedAt: DateTime.now(),
        canReply: true,
        actions: const [
          NotificationActionItem(
            actionId: 'reply_action',
            title: 'Reply',
            isQuickReply: true,
          ),
        ],
      );

      expect(item.key, equals('com.telegram|1|tag'));
      expect(item.actions.first.isQuickReply, isTrue);
      expect(item.isDismissed, isFalse);

      final dismissed = item.copyWith(isDismissed: true);
      expect(dismissed.isDismissed, isTrue);
    });

    test('SmsThreadItem and SmsMessageItem', () {
      final msg = SmsMessageItem(
        id: 'm1',
        threadId: 't1',
        address: '+1234567890',
        body: 'Security code: 5544',
        timestamp: DateTime.now(),
      );

      final thread = SmsThreadItem(
        threadId: 't1',
        address: '+1234567890',
        contactName: 'Service Desk',
        lastMessage: msg,
        unreadCount: 1,
        updatedAt: DateTime.now(),
      );

      expect(thread.displayName, equals('Service Desk'));
      expect(thread.unreadCount, equals(1));
    });

    test('ClipboardItem properties', () {
      final clip = ClipboardItem(
        id: 'clip-1',
        mime: 'text/plain',
        content: 'Secret text',
        hash: 'hash123',
        originDeviceId: 'mac-1',
        timestamp: DateTime.now(),
        isPinned: true,
      );

      expect(clip.isPinned, isTrue);
      expect(clip.mime, equals('text/plain'));
    });

    test('EventBus publishes and filters typed events', () async {
      final bus = EventBus();
      final stringEvents = <String>[];
      final intEvents = <int>[];

      bus.on<String>().listen(stringEvents.add);
      bus.on<int>().listen(intEvents.add);

      bus.emit('event-1');
      bus.emit(42);
      bus.emit('event-2');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(stringEvents, equals(['event-1', 'event-2']));
      expect(intEvents, equals([42]));

      bus.dispose();
    });
  });
}
