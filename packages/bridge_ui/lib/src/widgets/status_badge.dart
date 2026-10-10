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

  factory StatusBadgeConfig.connected({String? label, String? customLabel}) {
    return StatusBadgeConfig(
      label: customLabel ?? label ?? 'Connected',
      color: BridgeColors.success,
    );
  }

  factory StatusBadgeConfig.reconnecting({String? label, String? customLabel}) {
    return StatusBadgeConfig(
      label: customLabel ?? label ?? 'Reconnecting',
      color: BridgeColors.warning,
    );
  }

  factory StatusBadgeConfig.disconnected({String? label, String? customLabel}) {
    return StatusBadgeConfig(
      label: customLabel ?? label ?? 'Disconnected',
      color: BridgeColors.textSecondaryLight,
    );
  }

  factory StatusBadgeConfig.error({String? label, String? customLabel}) {
    return StatusBadgeConfig(
      label: customLabel ?? label ?? 'Error',
      color: BridgeColors.error,
    );
  }

  @override
  String toString() =>
      'StatusBadgeConfig(label: $label, color: 0x${color.toRadixString(16)})';
}
