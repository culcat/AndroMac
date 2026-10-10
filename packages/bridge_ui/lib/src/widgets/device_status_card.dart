import 'package:meta/meta.dart';
import 'battery_indicator.dart';
import 'status_badge.dart';

/// Presentation model and view configuration for the peer device status card.
@immutable
class DeviceStatusCardConfig {
  final String deviceName;
  final String platform;
  final bool isConnected;
  final int batteryLevel;
  final bool isCharging;
  final String networkType;
  final int signalStrength;
  final bool isDndActive;
  final DateTime? lastSyncTime;

  const DeviceStatusCardConfig({
    required this.deviceName,
    required this.platform,
    this.isConnected = false,
    this.batteryLevel = 100,
    this.isCharging = false,
    this.networkType = 'wifi',
    this.signalStrength = 4,
    this.isDndActive = false,
    this.lastSyncTime,
  });

  /// Status badge configuration for current state.
  StatusBadgeConfig get statusBadge => isConnected
      ? StatusBadgeConfig.connected(customLabel: 'Подключено')
      : StatusBadgeConfig.disconnected(customLabel: 'Отключено');

  /// Battery indicator configuration.
  BatteryIndicatorConfig get batteryIndicator => BatteryIndicatorConfig(
        batteryLevel: batteryLevel,
        isCharging: isCharging,
      );

  /// Network type display symbol.
  String get networkSymbol {
    switch (networkType.toLowerCase()) {
      case 'wifi':
        return '🛜 Wi-Fi';
      case 'cellular':
        return '📶 Сотовая';
      case 'ethernet':
        return '🌐 Ethernet';
      default:
        return '🚫 Нет сети';
    }
  }

  /// Platform icon representation.
  String get platformSymbol {
    switch (platform.toLowerCase()) {
      case 'android':
        return '🤖 Android';
      case 'macos':
        return '🍎 macOS';
      default:
        return '💻 Device';
    }
  }

  /// Formatted single-line status summary.
  String get summary =>
      '$deviceName • ${statusBadge.label} • ${batteryIndicator.displayLabel} • $networkSymbol';

  @override
  String toString() => summary;
}
