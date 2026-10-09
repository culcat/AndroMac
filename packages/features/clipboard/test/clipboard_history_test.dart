import 'package:test/test.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:clipboard_feature/clipboard_feature.dart';

void main() {
  group('ClipboardHistoryStore', () {
    test('evicts oldest unpinned item when capacity is exceeded', () {
      final store = ClipboardHistoryStore(maxCapacity: 3);

      final item1 = ClipboardItem(
        id: '1',
        mime: 'text/plain',
        content: 'One',
        hash: 'hash1',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );
      final item2 = ClipboardItem(
        id: '2',
        mime: 'text/plain',
        content: 'Two',
        hash: 'hash2',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );
      final item3 = ClipboardItem(
        id: '3',
        mime: 'text/plain',
        content: 'Three',
        hash: 'hash3',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );
      final item4 = ClipboardItem(
        id: '4',
        mime: 'text/plain',
        content: 'Four',
        hash: 'hash4',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );

      store.add(item1);
      store.add(item2);
      store.add(item3);
      expect(store.count, equals(3));

      // Adding 4th item evicts item1 (oldest unpinned)
      store.add(item4);
      expect(store.count, equals(3));
      expect(store.items.map((i) => i.id), equals(['4', '3', '2']));
    });

    test('retains pinned items even when capacity exceeded', () {
      final store = ClipboardHistoryStore(maxCapacity: 2);

      final item1 = ClipboardItem(
        id: '1',
        mime: 'text/plain',
        content: 'Pinned item',
        hash: 'hash1',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
        isPinned: true,
      );
      final item2 = ClipboardItem(
        id: '2',
        mime: 'text/plain',
        content: 'Unpinned item',
        hash: 'hash2',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );
      final item3 = ClipboardItem(
        id: '3',
        mime: 'text/plain',
        content: 'Newest item',
        hash: 'hash3',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );

      store.add(item1);
      store.add(item2);
      // Adding item3 should evict unpinned item2, keeping pinned item1
      store.add(item3);

      expect(store.items.map((i) => i.id), containsAll(['3', '1']));
      expect(store.items.any((i) => i.id == '2'), isFalse);
    });

    test('re-adding same hash moves item to top of history', () {
      final store = ClipboardHistoryStore(maxCapacity: 3);

      final itemA = ClipboardItem(
        id: '1',
        mime: 'text/plain',
        content: 'Text A',
        hash: 'hashA',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );
      final itemB = ClipboardItem(
        id: '2',
        mime: 'text/plain',
        content: 'Text B',
        hash: 'hashB',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );

      store.add(itemA);
      store.add(itemB);
      expect(store.items.first.id, equals('2'));

      // Re-add itemA with same hash
      final itemARefresh = ClipboardItem(
        id: '3',
        mime: 'text/plain',
        content: 'Text A',
        hash: 'hashA',
        originDeviceId: 'dev',
        timestamp: DateTime.now(),
      );
      store.add(itemARefresh);

      expect(store.count, equals(2));
      expect(store.items.first.id, equals('3'));
    });
  });
}
