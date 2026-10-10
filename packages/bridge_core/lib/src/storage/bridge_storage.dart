import 'dart:async';
import 'storage_records.dart';

/// Abstract contract for local encrypted persistence layer conforming to ADR-004.
abstract class BridgeStorage {
  // SMS
  Future<void> saveSms(SmsRecord record);
  Future<List<SmsRecord>> getSmsByThread(String threadId);
  Future<List<String>> getAllThreadIds();
  Future<List<SmsRecord>> searchSms(String query);
  Future<void> deleteThread(String threadId);

  // Notifications
  Future<void> saveNotification(NotificationRecord record);
  Future<List<NotificationRecord>> getActiveNotifications();
  Future<void> dismissNotification(String key);
  Future<int> purgeNotificationsOlderThan(Duration maxAge);

  // Clipboard
  Future<void> saveClipboard(ClipboardRecord record);
  Future<List<ClipboardRecord>> getClipboardHistory({int limit = 20});
  Future<void> pinClipboardItem(String id, bool isPinned);
  Future<int> evictOldestUnpinned({int maxCapacity = 20});
  Future<void> clearClipboardHistory();

  // Paired Devices
  Future<void> saveDevice(DeviceRecord record);
  Future<DeviceRecord?> getDevice(String deviceId);
  Future<List<DeviceRecord>> getAllDevices();
  Future<void> deleteDevice(String deviceId);
}

/// In-memory implementation of [BridgeStorage] simulating SQLCipher encrypted storage
/// for unit testing, fast lookups, and headless CLI emulators.
class MemoryEncryptedStorage implements BridgeStorage {
  final Map<String, SmsRecord> _smsMessages = <String, SmsRecord>{};
  final Map<String, NotificationRecord> _notifications = <String, NotificationRecord>{};
  final Map<String, ClipboardRecord> _clipboardItems = <String, ClipboardRecord>{};
  final Map<String, DeviceRecord> _devices = <String, DeviceRecord>{};

  // --- SMS ---

  @override
  Future<void> saveSms(SmsRecord record) async {
    _smsMessages[record.id] = record;
  }

  @override
  Future<List<SmsRecord>> getSmsByThread(String threadId) async {
    final list = _smsMessages.values.where((s) => s.threadId == threadId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  @override
  Future<List<String>> getAllThreadIds() async {
    final threadIds = _smsMessages.values.map((s) => s.threadId).toSet().toList();
    return threadIds;
  }

  @override
  Future<List<SmsRecord>> searchSms(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    return _smsMessages.values.where((s) {
      return s.address.toLowerCase().contains(q) ||
          s.body.toLowerCase().contains(q) ||
          s.threadId.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> deleteThread(String threadId) async {
    _smsMessages.removeWhere((_, s) => s.threadId == threadId);
  }

  // --- Notifications ---

  @override
  Future<void> saveNotification(NotificationRecord record) async {
    _notifications[record.key] = record;
  }

  @override
  Future<List<NotificationRecord>> getActiveNotifications() async {
    return _notifications.values.where((n) => !n.isDismissed).toList()
      ..sort((a, b) => b.postTime.compareTo(a.postTime));
  }

  @override
  Future<void> dismissNotification(String key) async {
    final existing = _notifications[key];
    if (existing != null) {
      _notifications[key] = existing.copyWith(isDismissed: true);
    }
  }

  @override
  Future<int> purgeNotificationsOlderThan(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    final keysToRemove = _notifications.entries
        .where((e) => e.value.postTime < cutoff)
        .map((e) => e.key)
        .toList();

    for (final key in keysToRemove) {
      _notifications.remove(key);
    }
    return keysToRemove.length;
  }

  // --- Clipboard ---

  @override
  Future<void> saveClipboard(ClipboardRecord record) async {
    _clipboardItems[record.id] = record;
    await evictOldestUnpinned();
  }

  @override
  Future<List<ClipboardRecord>> getClipboardHistory({int limit = 20}) async {
    final list = _clipboardItems.values.toList()
      ..sort((a, b) {
        // Pinned items stay at the top
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.timestamp.compareTo(a.timestamp);
      });

    return list.take(limit).toList();
  }

  @override
  Future<void> pinClipboardItem(String id, bool isPinned) async {
    final existing = _clipboardItems[id];
    if (existing != null) {
      _clipboardItems[id] = existing.copyWith(isPinned: isPinned);
    }
  }

  @override
  Future<int> evictOldestUnpinned({int maxCapacity = 20}) async {
    if (_clipboardItems.length <= maxCapacity) return 0;

    // Filter unpinned items sorted oldest first
    final unpinned = _clipboardItems.values.where((c) => !c.isPinned).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    var evictedCount = 0;
    while (_clipboardItems.length > maxCapacity && unpinned.isNotEmpty) {
      final oldest = unpinned.removeAt(0);
      _clipboardItems.remove(oldest.id);
      evictedCount++;
    }
    return evictedCount;
  }

  @override
  Future<void> clearClipboardHistory() async {
    // Preserve pinned items on clear
    _clipboardItems.removeWhere((_, c) => !c.isPinned);
  }

  // --- Paired Devices ---

  @override
  Future<void> saveDevice(DeviceRecord record) async {
    _devices[record.deviceId] = record;
  }

  @override
  Future<DeviceRecord?> getDevice(String deviceId) async {
    return _devices[deviceId];
  }

  @override
  Future<List<DeviceRecord>> getAllDevices() async {
    return _devices.values.toList()..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    _devices.remove(deviceId);
  }
}
