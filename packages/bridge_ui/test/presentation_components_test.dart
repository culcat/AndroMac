import 'package:test/test.dart';
import 'package:bridge_ui/bridge_ui.dart';

void main() {
  group('DeviceStatusCardConfig', () {
    test('computes status badge, network symbol, and summary formatting', () {
      final config = DeviceStatusCardConfig(
        deviceName: 'Pixel 8 Pro',
        platform: 'android',
        isConnected: true,
        batteryLevel: 85,
        isCharging: true,
        networkType: 'wifi',
      );

      expect(config.statusBadge.label, equals('Подключено'));
      expect(config.networkSymbol, contains('Wi-Fi'));
      expect(config.platformSymbol, contains('Android'));
      expect(config.summary, contains('Pixel 8 Pro'));
      expect(config.summary, contains('⚡ 85%'));
    });

    test('handles disconnected device state', () {
      final config = DeviceStatusCardConfig(
        deviceName: 'MacBook Air',
        platform: 'macos',
        isConnected: false,
        batteryLevel: 42,
        isCharging: false,
        networkType: 'none',
      );

      expect(config.statusBadge.label, equals('Отключено'));
      expect(config.networkSymbol, contains('Нет сети'));
      expect(config.platformSymbol, contains('macOS'));
    });
  });

  group('NotificationTileConfig', () {
    test('formats time and truncates body snippets correctly', () {
      final now = DateTime(2026, 10, 10, 14, 25).millisecondsSinceEpoch;
      final config = NotificationTileConfig(
        key: 'tg|100|group',
        packageName: 'org.telegram.messenger',
        appName: 'Telegram',
        title: 'Project Lead',
        text:
            'This is a very long notification body text that exceeds the snippet threshold for compact views',
        postTime: now,
        canReply: true,
      );

      expect(config.formattedTime, equals('14:25'));
      expect(config.appBadge, equals('[Telegram]'));
      expect(config.header, equals('Telegram • 14:25'));
      expect(config.bodySnippet(20), equals('This is a very long ...'));
      expect(config.canReply, isTrue);
    });
  });

  group('SmsConversationTileConfig & SmsMessageBubbleConfig', () {
    test(
        'derives contact initials and prioritizes contact name over phone number',
        () {
      final configWithName = SmsConversationTileConfig(
        threadId: 'th-1',
        contactName: 'Alexander Pushkin',
        phoneNumber: '+79991234567',
        lastMessageSnippet: 'Я помню чудное мгновенье...',
        unreadCount: 3,
        lastTimestamp: DateTime(2026, 10, 10, 18, 5).millisecondsSinceEpoch,
      );

      expect(configWithName.displayName, equals('Alexander Pushkin'));
      expect(configWithName.avatarInitials, equals('AP'));
      expect(configWithName.formattedTime, equals('18:05'));
      expect(configWithName.hasUnread, isTrue);

      final configNumberOnly = SmsConversationTileConfig(
        threadId: 'th-2',
        contactName: null,
        phoneNumber: '+79998887766',
        lastMessageSnippet: 'Hello!',
        unreadCount: 0,
        lastTimestamp: DateTime(2026, 10, 10, 9, 30).millisecondsSinceEpoch,
      );

      expect(configNumberOnly.displayName, equals('+79998887766'));
      expect(configNumberOnly.avatarInitials, equals('+'));
      expect(configNumberOnly.hasUnread, isFalse);
    });

    test('formats message bubble status ticks and multi-SIM badges', () {
      final bubbleOutbound = SmsMessageBubbleConfig(
        messageId: 'msg-1',
        body: 'Outbound message text',
        isOutbound: true,
        timestamp: DateTime(2026, 10, 10, 12, 0).millisecondsSinceEpoch,
        simSlot: 1,
        deliveryStatus: 'delivered',
      );

      expect(bubbleOutbound.simBadge, equals('SIM 2'));
      expect(bubbleOutbound.statusTick, equals('✓✓'));
      expect(bubbleOutbound.formattedTime, equals('12:00'));

      final bubbleInbound = SmsMessageBubbleConfig(
        messageId: 'msg-2',
        body: 'Inbound message text',
        isOutbound: false,
        timestamp: DateTime(2026, 10, 10, 12, 1).millisecondsSinceEpoch,
      );

      expect(bubbleInbound.statusTick, isEmpty);
    });
  });

  group('ClipboardTileConfig', () {
    test('computes character count, preview snippet, and origin device badge',
        () {
      final config = ClipboardTileConfig(
        id: 'clip-1',
        content: 'https://github.com/culcat/AndroMac\nLine 2',
        originDeviceId: 'mac-studio-1',
        isPinned: true,
        timestamp: DateTime(2026, 10, 10, 15, 30).millisecondsSinceEpoch,
      );

      expect(config.charCount, equals(41));
      expect(config.originBadge, contains('macOS'));
      expect(config.pinSymbol, equals('📌'));
      expect(config.formattedTime, equals('15:30'));
      expect(config.snippet(20), equals('https://github.com/c...'));
    });
  });

  group('FileTransferCardConfig', () {
    test('formats file sizes accurately across magnitude units', () {
      expect(FileTransferCardConfig.formatBytes(500), equals('500 B'));
      expect(FileTransferCardConfig.formatBytes(1536), equals('1.5 KB'));
      expect(FileTransferCardConfig.formatBytes(10485760), equals('10.0 MB'));
      expect(FileTransferCardConfig.formatBytes(1610612736), equals('1.50 GB'));
    });

    test('calculates percentage, progress description, and finished states',
        () {
      final active = FileTransferCardConfig(
        transferId: 'tx-1',
        fileName: 'archive.zip',
        fileSizeBytes: 10000000,
        transferredBytes: 5000000,
        isOutbound: true,
        state: 'transferring',
      );

      expect(active.percentage, equals(50.0));
      expect(active.directionLabel, contains('Отправка'));
      expect(active.isFinished, isFalse);
      expect(active.statusBadge, contains('50%'));

      final completed = FileTransferCardConfig(
        transferId: 'tx-2',
        fileName: 'photo.jpg',
        fileSizeBytes: 2000000,
        transferredBytes: 2000000,
        isOutbound: false,
        state: 'completed',
      );

      expect(completed.percentage, equals(100.0));
      expect(completed.directionLabel, contains('Получение'));
      expect(completed.isFinished, isTrue);
      expect(completed.statusBadge, contains('Завершено'));
    });
  });

  group('DiagnosticsChecklistConfig', () {
    test('calculates healthy items, pass rates, and summary text', () {
      final checklist = DiagnosticsChecklistConfig(
        items: const [
          DiagnosticsItemConfig(
            id: 'lan',
            title: 'Локальная сеть',
            description: 'Wi-Fi подключен',
            status: 'ok',
          ),
          DiagnosticsItemConfig(
            id: 'fgs',
            title: 'Фоновая служба',
            description: 'Служба активна',
            status: 'ok',
          ),
          DiagnosticsItemConfig(
            id: 'nls',
            title: 'Уведомления',
            description: 'Требуется разрешение',
            status: 'error',
            actionLabel: 'Открыть настройки',
          ),
        ],
      );

      expect(checklist.totalCount, equals(3));
      expect(checklist.healthyCount, equals(2));
      expect(checklist.allPassed, isFalse);
      expect(checklist.summary, equals('2/3 проверок пройдено'));
      expect(checklist.items[2].statusIcon, equals('❌'));
    });
  });
}
