import 'dart:async';

/// Dart platform contract for Android native integrations (Kotlin services, NLS, telephony).
abstract class AndroidBridgePlatform {
  static AndroidBridgePlatform instance = _UnimplementedAndroidPlatform();

  Future<void> startForegroundService();
  Future<void> stopForegroundService();
  Future<bool> sendSms({
    required String address,
    required String body,
    int simSlot = 0,
    String? clientMessageId,
  });
  Future<void> copyToClipboard(String text);
  Future<void> openNotificationListenerSettings();
  Future<void> requestIgnoreBatteryOptimizations();

  /// Callbacks invoked from Kotlin into Flutter
  void registerCallbacks({
    required void Function(Map<String, dynamic> notification) onNotificationPosted,
    required void Function(String key) onNotificationDismissed,
    required void Function(Map<String, dynamic> sms) onSmsReceived,
    required void Function(String text) onClipboardCaptured,
    required void Function(int batteryLevel, bool isCharging) onBatteryChanged,
  });
}

class _UnimplementedAndroidPlatform extends AndroidBridgePlatform {
  @override
  Future<void> startForegroundService() async {}
  @override
  Future<void> stopForegroundService() async {}
  @override
  Future<bool> sendSms({
    required String address,
    required String body,
    int simSlot = 0,
    String? clientMessageId,
  }) async => false;
  @override
  Future<void> copyToClipboard(String text) async {}
  @override
  Future<void> openNotificationListenerSettings() async {}
  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}
  @override
  void registerCallbacks({
    required void Function(Map<String, dynamic> notification) onNotificationPosted,
    required void Function(String key) onNotificationDismissed,
    required void Function(Map<String, dynamic> sms) onSmsReceived,
    required void Function(String text) onClipboardCaptured,
    required void Function(int batteryLevel, bool isCharging) onBatteryChanged,
  }) {}
}
