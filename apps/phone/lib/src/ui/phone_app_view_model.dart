import 'package:meta/meta.dart';

/// Navigation tabs in the Android phone application.
enum PhoneTab {
  status,
  pairing,
  settings,
  diagnostics,
}

/// State representation for the Android phone UI.
@immutable
class PhoneAppViewModel {
  final PhoneTab currentTab;
  final bool isConnected;
  final String? peerMacName;
  final String? peerDeviceId;
  final int batteryLevel;
  final bool isCharging;
  final bool isForegroundServiceRunning;
  final bool isNotificationListenerGranted;
  final bool isBatteryOptimizationIgnored;
  final bool hasSmsPermission;
  final int mirroredNotificationsCount;
  final int syncedSmsCount;
  final int clipboardSyncCount;

  const PhoneAppViewModel({
    this.currentTab = PhoneTab.status,
    this.isConnected = false,
    this.peerMacName,
    this.peerDeviceId,
    this.batteryLevel = 100,
    this.isCharging = false,
    this.isForegroundServiceRunning = false,
    this.isNotificationListenerGranted = false,
    this.isBatteryOptimizationIgnored = false,
    this.hasSmsPermission = false,
    this.mirroredNotificationsCount = 0,
    this.syncedSmsCount = 0,
    this.clipboardSyncCount = 0,
  });

  PhoneAppViewModel copyWith({
    PhoneTab? currentTab,
    bool? isConnected,
    String? peerMacName,
    String? peerDeviceId,
    int? batteryLevel,
    bool? isCharging,
    bool? isForegroundServiceRunning,
    bool? isNotificationListenerGranted,
    bool? isBatteryOptimizationIgnored,
    bool? hasSmsPermission,
    int? mirroredNotificationsCount,
    int? syncedSmsCount,
    int? clipboardSyncCount,
  }) {
    return PhoneAppViewModel(
      currentTab: currentTab ?? this.currentTab,
      isConnected: isConnected ?? this.isConnected,
      peerMacName: peerMacName ?? this.peerMacName,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      isForegroundServiceRunning:
          isForegroundServiceRunning ?? this.isForegroundServiceRunning,
      isNotificationListenerGranted:
          isNotificationListenerGranted ?? this.isNotificationListenerGranted,
      isBatteryOptimizationIgnored:
          isBatteryOptimizationIgnored ?? this.isBatteryOptimizationIgnored,
      hasSmsPermission: hasSmsPermission ?? this.hasSmsPermission,
      mirroredNotificationsCount:
          mirroredNotificationsCount ?? this.mirroredNotificationsCount,
      syncedSmsCount: syncedSmsCount ?? this.syncedSmsCount,
      clipboardSyncCount: clipboardSyncCount ?? this.clipboardSyncCount,
    );
  }

  @override
  String toString() =>
      'PhoneAppViewModel(tab: ${currentTab.name}, connected: $isConnected, mac: $peerMacName, battery: $batteryLevel%)';
}
