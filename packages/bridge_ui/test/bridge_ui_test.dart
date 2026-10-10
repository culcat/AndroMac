import 'package:test/test.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_ui/bridge_ui.dart';

void main() {
  group('BridgeTheme & Design Tokens', () {
    test('theme palettes resolve expected primary and background colors', () {
      final light = BridgeThemePalette.light();
      expect(light.isDark, isFalse);
      expect(light.primary, equals(BridgeColors.primary));
      expect(light.background, equals(BridgeColors.backgroundLight));

      final dark = BridgeThemePalette.dark();
      expect(dark.isDark, isTrue);
      expect(dark.primary, equals(BridgeColors.primaryDark));
      expect(dark.background, equals(BridgeColors.backgroundDark));
    });

    test('spacing and radii tokens are monotonically increasing', () {
      expect(BridgeSpacing.xs, lessThan(BridgeSpacing.sm));
      expect(BridgeSpacing.sm, lessThan(BridgeSpacing.md));
      expect(BridgeSpacing.md, lessThan(BridgeSpacing.lg));
      expect(BridgeSpacing.lg, lessThan(BridgeSpacing.xl));

      expect(BridgeRadii.sm, lessThan(BridgeRadii.md));
      expect(BridgeRadii.md, lessThan(BridgeRadii.lg));
      expect(BridgeRadii.lg, lessThan(BridgeRadii.full));
    });
  });

  group('UI Presentation Component Configs', () {
    test('StatusBadgeConfig resolves correct states', () {
      final connected = StatusBadgeConfig.connected();
      expect(connected.color, equals(BridgeColors.success));
      expect(connected.label, equals('Connected'));

      final reconnecting = StatusBadgeConfig.reconnecting();
      expect(reconnecting.color, equals(BridgeColors.warning));

      final disconnected = StatusBadgeConfig.disconnected();
      expect(disconnected.color, equals(BridgeColors.textSecondaryLight));

      final error = StatusBadgeConfig.error();
      expect(error.color, equals(BridgeColors.error));
    });

    test('BatteryIndicatorConfig formats level and charging state', () {
      // Normal battery
      final normal =
          BatteryIndicatorConfig.resolve(level: 75, isCharging: false);
      expect(normal.label, equals('75%'));
      expect(normal.color, equals(BridgeColors.success));
      expect(normal.icon, equals('🔋'));

      // Low battery (<= 20%)
      final low = BatteryIndicatorConfig.resolve(level: 15, isCharging: false);
      expect(low.label, equals('15%'));
      expect(low.color, equals(BridgeColors.error));
      expect(low.icon, equals('🪫'));

      // Charging
      final charging =
          BatteryIndicatorConfig.resolve(level: 40, isCharging: true);
      expect(charging.label, equals('⚡ 40%'));
      expect(charging.icon, equals('⚡'));
      expect(charging.color, equals(BridgeColors.success));

      // Clamping test
      final clamped =
          BatteryIndicatorConfig.resolve(level: 150, isCharging: false);
      expect(clamped.level, equals(100));
    });

    test('SasDisplayCard formats numeric and emoji codes', () {
      final sas = SasResult(numericCode: '492-019', emojiCode: '🚀🍕🐶⚡');
      final card = SasDisplayCard.fromSasResult(sas);

      expect(card.formattedNumeric, equals('492-019'));
      expect(card.emojiCode, equals('🚀🍕🐶⚡'));
      expect(card.instruction, contains('identical'));
    });
  });
}
