import 'dart:async';

/// Dart platform contract for macOS native integrations (Swift AppKit, UserNotifications, Pasteboard).
abstract class MacOsBridgePlatform {
  static MacOsBridgePlatform instance = _UnimplementedMacOsPlatform();

  Future<void> showNotification({
    required String identifier,
    required String title,
    String? subtitle,
    required String body,
    bool canReply = true,
  });

  Future<void> removeNotification(String identifier);

  Future<void> updateTray({
    String? title,
    required String tooltip,
    required bool isConnected,
    String? batteryBadge,
  });

  Future<void> copyToPasteboard(String text);
  Future<int> getPasteboardChangeCount();
  Future<String?> readPasteboard();
  Future<void> registerSleepWakeObserver();

  /// Callbacks invoked from Swift into Flutter
  void registerCallbacks({
    required void Function(String identifier, String actionId, String? replyText)
        onNotificationAction,
    required void Function(String identifier) onNotificationDismissed,
    required void Function() onSystemSleep,
    required void Function() onSystemWake,
    required void Function(String text) onPasteboardChanged,
  });
}

class _UnimplementedMacOsPlatform extends MacOsBridgePlatform {
  @override
  Future<void> showNotification({
    required String identifier,
    required String title,
    String? subtitle,
    required String body,
    bool canReply = true,
  }) async {}

  @override
  Future<void> removeNotification(String identifier) async {}

  @override
  Future<void> updateTray({
    String? title,
    required String tooltip,
    required bool isConnected,
    String? batteryBadge,
  }) async {}

  @override
  Future<void> copyToPasteboard(String text) async {}

  @override
  Future<int> getPasteboardChangeCount() async => 0;

  @override
  Future<String?> readPasteboard() async => null;

  @override
  Future<void> registerSleepWakeObserver() async {}

  @override
  void registerCallbacks({
    required void Function(String identifier, String actionId, String? replyText)
        onNotificationAction,
    required void Function(String identifier) onNotificationDismissed,
    required void Function() onSystemSleep,
    required void Function() onSystemWake,
    required void Function(String text) onPasteboardChanged,
  }) {}
}
