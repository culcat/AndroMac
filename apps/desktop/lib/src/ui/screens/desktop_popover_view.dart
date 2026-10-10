import 'package:meta/meta.dart';
import 'package:bridge_ui/bridge_ui.dart';

/// Presentation configuration for the compact macOS menu bar popover view.
@immutable
class DesktopPopoverViewConfig {
  final bool isConnected;
  final String? peerDeviceName;
  final int? batteryLevel;
  final bool isCharging;
  final List<NotificationTileConfig> recentNotifications;
  final BridgeLocale currentLocale;

  const DesktopPopoverViewConfig({
    this.isConnected = false,
    this.peerDeviceName,
    this.batteryLevel,
    this.isCharging = false,
    this.recentNotifications = const [],
    this.currentLocale = BridgeLocale.ru,
  });

  /// Localized UI strings.
  BridgeStrings get strings => BridgeL10n.forLocale(currentLocale);

  /// Status badge configuration.
  StatusBadgeConfig get statusBadge => isConnected
      ? StatusBadgeConfig.connected(customLabel: strings.connected)
      : StatusBadgeConfig.disconnected(customLabel: strings.disconnected);

  /// Battery indicator configuration.
  BatteryIndicatorConfig? get batteryIndicator => batteryLevel != null
      ? BatteryIndicatorConfig(
          batteryLevel: batteryLevel!,
          isCharging: isCharging,
        )
      : null;

  /// Header text representation.
  String get headerText {
    if (isConnected && peerDeviceName != null) {
      final battery = batteryIndicator?.displayLabel ?? '';
      return '$peerDeviceName • $battery';
    }
    return 'AndroMac • ${strings.disconnected}';
  }

  /// Top 3 recent active notifications to show in the compact popover.
  List<NotificationTileConfig> get topNotifications =>
      recentNotifications.take(3).toList();

  @override
  String toString() =>
      'DesktopPopoverView(header: $headerText, notifs: ${topNotifications.length})';
}
