import 'package:bridge_core/bridge_core.dart';

/// In-memory bounded clipboard history store with de-duplication and pinning support.
class ClipboardHistoryStore {
  final int maxCapacity;
  final List<ClipboardItem> _items = <ClipboardItem>[];

  ClipboardHistoryStore({this.maxCapacity = 20});

  /// Read-only snapshot of history items (newest first).
  List<ClipboardItem> get items => List.unmodifiable(_items);

  /// Total count of saved clipboard entries.
  int get count => _items.length;

  /// Adds a new clipboard item.
  ///
  /// If an item with identical content hash already exists, it is moved to the top.
  /// If the history exceeds [maxCapacity], oldest unpinned items are evicted.
  void add(ClipboardItem item) {
    // Remove existing item with identical hash if present (refresh position)
    _items.removeWhere((existing) => existing.hash == item.hash);

    // Insert at front (newest first)
    _items.insert(0, item);

    // Evict oldest unpinned items if over capacity
    while (_items.length > maxCapacity) {
      final oldestUnpinnedIndex = _items.lastIndexWhere((i) => !i.isPinned);
      if (oldestUnpinnedIndex != -1) {
        _items.removeAt(oldestUnpinnedIndex);
      } else {
        // If all items are pinned, do not evict
        break;
      }
    }
  }

  /// Toggles the pinned state of an item by [id].
  void togglePin(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final current = _items[index];
      _items[index] = current.copyWith(isPinned: !current.isPinned);
    }
  }

  /// Removes an item by [id].
  void remove(String id) {
    _items.removeWhere((i) => i.id == id);
  }

  /// Clears all unpinned history items.
  void clearUnpinned() {
    _items.removeWhere((i) => !i.isPinned);
  }

  /// Clears entire history.
  void clearAll() {
    _items.clear();
  }
}
