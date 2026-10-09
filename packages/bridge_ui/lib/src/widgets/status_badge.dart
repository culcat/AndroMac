import 'package:meta/meta.dart';
import '../theme/bridge_theme.dart';

/// Configuration and display properties for peer connection status badges.
@immutable
class StatusBadgeConfig {
  final String label;
  final int color;
  final String dotSymbol;

  const StatusBadgeConfig({
    required this.label,
    required this.color,
    this.dotSymbol = '●',
  });

  factory StatusBadgeConfig.connected([String label = 'Connected']) {
    return StatusBadgeConfig(
      label: label,
      color: BridgeColors.success,
    );
  }

  factory StatusBadgeConfig.reconnecting([String label = 'Reconnecting']) {
    return StatusBadgeConfig(
      label: label,
      color: BridgeColors.warning,
    );
  }

  factory StatusBadgeConfig.disconnected([String label = 'Disconnected']) {
    return StatusBadgeConfig(
      label: label,
      color: BridgeColors.textSecondaryLight,
    );
  }

  factory StatusBadgeConfig.error([String label = 'Error']) {
    return StatusBadgeConfig(
      label: label,
      color: BridgeColors.error,
    );
  }

  @override
  String toString() => 'StatusBadgeConfig(label: $label, color: 0x${color.toRadixString(16)})';
}
