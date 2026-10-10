import 'package:meta/meta.dart';
import 'package:bridge_ui/bridge_ui.dart';
import '../phone_app_view_model.dart';

/// Presentation configuration and coordinator for the Android phone main screen.
@immutable
class PhoneMainViewConfig {
  final PhoneTab activeTab;
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
  final SasDisplayCard? activeSasVerification;
  final BridgeLocale currentLocale;

  const PhoneMainViewConfig({
    this.activeTab = PhoneTab.status,
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
    this.activeSasVerification,
    this.currentLocale = BridgeLocale.ru,
  });

  /// Localized UI strings based on the currently selected locale.
  BridgeStrings get strings => BridgeL10n.forLocale(currentLocale);

  /// Status badge configuration.
  StatusBadgeConfig get statusBadge => isConnected
      ? StatusBadgeConfig.connected(customLabel: strings.connected)
      : StatusBadgeConfig.disconnected(customLabel: strings.disconnected);

  /// Battery indicator configuration.
  BatteryIndicatorConfig get batteryIndicator => BatteryIndicatorConfig(
        batteryLevel: batteryLevel,
        isCharging: isCharging,
      );

  /// Peer Mac status card configuration.
  DeviceStatusCardConfig get peerMacStatusCard => DeviceStatusCardConfig(
        deviceName: peerMacName ?? 'MacBook Pro',
        platform: 'macos',
        isConnected: isConnected,
        batteryLevel: batteryLevel,
        isCharging: isCharging,
        networkType: 'wifi',
      );

  /// Dynamically evaluated diagnostics checklist for system permissions and background health.
  DiagnosticsChecklistConfig get diagnosticsChecklist {
    final items = <DiagnosticsItemConfig>[
      DiagnosticsItemConfig(
        id: 'fgs',
        title: strings.foregroundService,
        description: isForegroundServiceRunning
            ? 'Служба активна'
            : 'Служба остановлена',
        status: isForegroundServiceRunning ? 'ok' : 'error',
        actionLabel: isForegroundServiceRunning ? null : strings.fixAction,
      ),
      DiagnosticsItemConfig(
        id: 'nls',
        title: strings.notificationAccess,
        description: isNotificationListenerGranted
            ? 'Доступ предоставлен'
            : 'Требуется разрешение в настройках',
        status: isNotificationListenerGranted ? 'ok' : 'warning',
        actionLabel: isNotificationListenerGranted ? null : strings.fixAction,
      ),
      DiagnosticsItemConfig(
        id: 'battery',
        title: strings.batteryOptimization,
        description: isBatteryOptimizationIgnored
            ? 'Исключено из оптимизации'
            : 'Может усыпляться системой',
        status: isBatteryOptimizationIgnored ? 'ok' : 'warning',
        actionLabel: isBatteryOptimizationIgnored ? null : strings.fixAction,
      ),
      DiagnosticsItemConfig(
        id: 'sms',
        title: strings.smsPermission,
        description: hasSmsPermission
            ? 'Разрешения выданы'
            : 'Чтение/отправка SMS ограничены',
        status: hasSmsPermission ? 'ok' : 'warning',
        actionLabel: hasSmsPermission ? null : strings.fixAction,
      ),
    ];

    return DiagnosticsChecklistConfig(items: items);
  }

  /// Bottom navigation bar tab label.
  String tabLabel(PhoneTab tab) {
    switch (tab) {
      case PhoneTab.status:
        return '📱 ${strings.deviceStatus}';
      case PhoneTab.pairing:
        return '🔗 Сопряжение';
      case PhoneTab.settings:
        return '⚙️ ${strings.clipboard}';
      case PhoneTab.diagnostics:
        final checklist = diagnosticsChecklist;
        return checklist.allPassed
            ? '🩺 ${strings.diagnostics} ✅'
            : '🩺 ${strings.diagnostics} (${checklist.healthyCount}/${checklist.totalCount})';
    }
  }

  /// Screen title representation.
  String get screenTitle {
    switch (activeTab) {
      case PhoneTab.status:
        return isConnected ? '${strings.connected} (${peerMacName ?? "Mac"})' : 'AndroMac';
      case PhoneTab.pairing:
        return strings.scanQrCode;
      case PhoneTab.settings:
        return 'Настройки синхронизации';
      case PhoneTab.diagnostics:
        return strings.diagnostics;
    }
  }

  PhoneMainViewConfig copyWith({
    PhoneTab? activeTab,
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
    SasDisplayCard? activeSasVerification,
    BridgeLocale? currentLocale,
  }) {
    return PhoneMainViewConfig(
      activeTab: activeTab ?? this.activeTab,
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
      activeSasVerification:
          activeSasVerification ?? this.activeSasVerification,
      currentLocale: currentLocale ?? this.currentLocale,
    );
  }

  @override
  String toString() =>
      'PhoneMainView(tab: ${activeTab.name}, connected: $isConnected, mac: $peerMacName, battery: $batteryLevel%)';
}
