import 'package:bridge_core/bridge_core.dart';

/// In-memory store tracking active mirrored notifications on the Mac controller.
class NotificationStore {
  final Map<String, NotificationItem> _active = <String, NotificationItem>{};

  /// Read-only snapshot of all active, non-dismissed notifications.
  List<NotificationItem> get activeNotifications =>
      List.unmodifiable(_active.values.where((n) => !n.isDismissed));

  /// Total count of active notifications.
  int get count => activeNotifications.length;

  /// Adds a new notification or updates an existing one (e.g. progress bar or updated text).
  void addOrUpdate(NotificationItem item) {
    _active[item.key] = item;
  }

  /// Marks a notification as dismissed.
  void markDismissed(String key) {
    final existing = _active[key];
    if (existing != null) {
      _active[key] = existing.copyWith(isDismissed: true);
    }
  }

  /// Permanently removes a notification by [key].
  void remove(String key) {
    _active.remove(key);
  }

  /// Retrieves a notification by [key].
  NotificationItem? getByKey(String key) => _active[key];

  /// Clears all notifications.
  void clear() {
    _active.clear();
  }
}
