import 'android_platform_interface.dart';
import 'macos_platform_interface.dart';

/// Testable in-memory mock implementation of [AndroidBridgePlatform].
class MockAndroidPlatform extends AndroidBridgePlatform {
  bool isForegroundServiceRunning = false;
  final List<Map<String, dynamic>> sentSmsList = <Map<String, dynamic>>[];
  final List<String> copiedClipboardItems = <String>[];
  bool notificationSettingsOpened = false;
  bool batteryOptimizationsRequested = false;

  void Function(Map<String, dynamic> notification)? _onNotificationPosted;
  void Function(String key)? _onNotificationDismissed;
  void Function(Map<String, dynamic> sms)? _onSmsReceived;
  void Function(String text)? _onClipboardCaptured;
  void Function(int batteryLevel, bool isCharging)? _onBatteryChanged;

  @override
  Future<void> startForegroundService() async {
    isForegroundServiceRunning = true;
  }

  @override
  Future<void> stopForegroundService() async {
    isForegroundServiceRunning = false;
  }

  @override
  Future<bool> sendSms({
    required String address,
    required String body,
    int simSlot = 0,
    String? clientMessageId,
  }) async {
    sentSmsList.add({
      'address': address,
      'body': body,
      'simSlot': simSlot,
      'clientMessageId': clientMessageId,
    });
    return true;
  }

  @override
  Future<void> copyToClipboard(String text) async {
    copiedClipboardItems.add(text);
  }

  @override
  Future<void> openNotificationListenerSettings() async {
    notificationSettingsOpened = true;
  }

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    batteryOptimizationsRequested = true;
  }

  @override
  void registerCallbacks({
    required void Function(Map<String, dynamic> notification)
        onNotificationPosted,
    required void Function(String key) onNotificationDismissed,
    required void Function(Map<String, dynamic> sms) onSmsReceived,
    required void Function(String text) onClipboardCaptured,
    required void Function(int batteryLevel, bool isCharging) onBatteryChanged,
  }) {
    _onNotificationPosted = onNotificationPosted;
    _onNotificationDismissed = onNotificationDismissed;
    _onSmsReceived = onSmsReceived;
    _onClipboardCaptured = onClipboardCaptured;
    _onBatteryChanged = onBatteryChanged;
  }

  // Simulation triggers for tests
  void simulateNotificationPosted(Map<String, dynamic> notif) =>
      _onNotificationPosted?.call(notif);
  void simulateNotificationDismissed(String key) =>
      _onNotificationDismissed?.call(key);
  void simulateSmsReceived(Map<String, dynamic> sms) =>
      _onSmsReceived?.call(sms);
  void simulateClipboardCaptured(String text) =>
      _onClipboardCaptured?.call(text);
  void simulateBatteryChanged(int level, bool charging) =>
      _onBatteryChanged?.call(level, charging);
}

/// Testable in-memory mock implementation of [MacOsBridgePlatform].
class MockMacOsPlatform extends MacOsBridgePlatform {
  final List<Map<String, dynamic>> displayedNotifications =
      <Map<String, dynamic>>[];
  final List<String> removedNotificationIds = <String>[];
  final List<Map<String, dynamic>> trayStatusHistory = <Map<String, dynamic>>[];
  final List<String> pasteboardCopies = <String>[];
  int pasteboardChangeCount = 0;
  String? currentPasteboardText;

  void Function(String identifier, String actionId, String? replyText)?
      _onNotificationAction;
  void Function(String identifier)? _onNotificationDismissed;
  void Function()? _onSystemSleep;
  void Function()? _onSystemWake;
  void Function(String text)? _onPasteboardChanged;

  @override
  Future<void> showNotification({
    required String identifier,
    required String title,
    String? subtitle,
    required String body,
    bool canReply = true,
  }) async {
    displayedNotifications.add({
      'identifier': identifier,
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'canReply': canReply,
    });
  }

  @override
  Future<void> removeNotification(String identifier) async {
    removedNotificationIds.add(identifier);
    displayedNotifications.removeWhere((n) => n['identifier'] == identifier);
  }

  @override
  Future<void> updateTray({
    String? title,
    required String tooltip,
    required bool isConnected,
    String? batteryBadge,
  }) async {
    trayStatusHistory.add({
      'title': title,
      'tooltip': tooltip,
      'isConnected': isConnected,
      'batteryBadge': batteryBadge,
    });
  }

  @override
  Future<void> copyToPasteboard(String text) async {
    pasteboardCopies.add(text);
    currentPasteboardText = text;
    pasteboardChangeCount++;
  }

  @override
  Future<int> getPasteboardChangeCount() async => pasteboardChangeCount;

  @override
  Future<String?> readPasteboard() async => currentPasteboardText;

  @override
  Future<void> registerSleepWakeObserver() async {}

  @override
  void registerCallbacks({
    required void Function(
            String identifier, String actionId, String? replyText)
        onNotificationAction,
    required void Function(String identifier) onNotificationDismissed,
    required void Function() onSystemSleep,
    required void Function() onSystemWake,
    required void Function(String text) onPasteboardChanged,
  }) {
    _onNotificationAction = onNotificationAction;
    _onNotificationDismissed = onNotificationDismissed;
    _onSystemSleep = onSystemSleep;
    _onSystemWake = onSystemWake;
    _onPasteboardChanged = onPasteboardChanged;
  }

  // Simulation triggers for tests
  void simulateNotificationAction(String id, String action, String? reply) =>
      _onNotificationAction?.call(id, action, reply);
  void simulateNotificationDismissed(String identifier) =>
      _onNotificationDismissed?.call(identifier);
  void simulateSleep() => _onSystemSleep?.call();
  void simulateWake() => _onSystemWake?.call();
  void simulatePasteboardChange(String text) =>
      _onPasteboardChanged?.call(text);
}
