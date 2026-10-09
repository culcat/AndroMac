import 'package:meta/meta.dart';
import '../theme/bridge_theme.dart';

/// Configuration and display properties for device battery level indicator.
@immutable
class BatteryIndicatorConfig {
  final int level; // 0 - 100
  final bool isCharging;
  final int color;
  final String icon;
  final String label;

  const BatteryIndicatorConfig({
    required this.level,
    required this.isCharging,
    required this.color,
    required this.icon,
    required this.label,
  });

  factory BatteryIndicatorConfig.resolve({
    required int level,
    required bool isCharging,
  }) {
    final clampedLevel = level.clamp(0, 100);
    final isLow = clampedLevel <= 20;

    final int color;
    final String icon;

    if (isCharging) {
      color = BridgeColors.success;
      icon = '⚡';
    } else if (isLow) {
      color = BridgeColors.error;
      icon = '🪫';
    } else {
      color = BridgeColors.success;
      icon = '🔋';
    }

    final label = isCharging ? '⚡ $clampedLevel%' : '$clampedLevel%';

    return BatteryIndicatorConfig(
      level: clampedLevel,
      isCharging: isCharging,
      color: color,
      icon: icon,
      label: label,
    );
  }

  @override
  String toString() => 'BatteryIndicatorConfig(level: $level%, charging: $isCharging, label: $label)';
}
