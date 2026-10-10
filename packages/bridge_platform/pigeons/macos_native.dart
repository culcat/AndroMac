// Pigeon schema definition for macOS Swift platform channels.
// Run with: dart run pigeon --input pigeons/macos_native.dart

class PigeonMacNotification {
  String identifier;
  String title;
  String? subtitle;
  String body;
  bool canReply;

  PigeonMacNotification({
    required this.identifier,
    required this.title,
    this.subtitle,
    required this.body,
    required this.canReply,
  });
}

class PigeonTrayStatus {
  String? title;
  String tooltip;
  bool isConnected;
  String? batteryBadge;

  PigeonTrayStatus({
    this.title,
    required this.tooltip,
    required this.isConnected,
    this.batteryBadge,
  });
}

/// Host API implemented by macOS Swift native modules (AppKit, UserNotifications).
abstract class MacOsHostApi {
  void showNotification(PigeonMacNotification notification);
  void removeNotification(String identifier);
  void updateTray(PigeonTrayStatus status);
  void copyToPasteboard(String text);
  int getPasteboardChangeCount();
  String? readPasteboard();
  void registerSleepWakeObserver();
}

/// Flutter API called from macOS Swift modules into the Flutter engine.
abstract class MacOsFlutterApi {
  void onNotificationAction(
      String identifier, String actionId, String? replyText);
  void onNotificationDismissed(String identifier);
  void onSystemSleep();
  void onSystemWake();
  void onPasteboardChanged(String text);
}
