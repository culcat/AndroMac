import 'package:test/test.dart';
import 'package:bridge_ui/bridge_ui.dart';
import 'package:andromac_phone/phone_app.dart';

void main() {
  group('PhoneMainViewConfig', () {
    test('computes tab labels, status badges, and screen titles', () {
      final view = PhoneMainViewConfig(
        activeTab: PhoneTab.status,
        isConnected: true,
        peerMacName: 'Alex Mac Studio',
        batteryLevel: 88,
        isCharging: true,
        isForegroundServiceRunning: true,
        isNotificationListenerGranted: true,
        isBatteryOptimizationIgnored: true,
        hasSmsPermission: true,
        currentLocale: BridgeLocale.ru,
      );

      expect(view.statusBadge.label, equals('Подключено'));
      expect(view.batteryIndicator.displayLabel, equals('88% ⚡'));
      expect(view.peerMacStatusCard.deviceName, equals('Alex Mac Studio'));
      expect(view.peerMacStatusCard.platform, equals('macos'));
      expect(view.screenTitle, contains('Alex Mac Studio'));

      // Check tab labels
      expect(view.tabLabel(PhoneTab.status), contains('Статус'));
      expect(view.tabLabel(PhoneTab.pairing), contains('Сопряжение'));
      expect(view.tabLabel(PhoneTab.diagnostics), contains('✅'));
    });

    test('evaluates diagnostics checklist based on permission health', () {
      final healthyView = PhoneMainViewConfig(
        isForegroundServiceRunning: true,
        isNotificationListenerGranted: true,
        isBatteryOptimizationIgnored: true,
        hasSmsPermission: true,
      );

      final healthyChecklist = healthyView.diagnosticsChecklist;
      expect(healthyChecklist.totalCount, equals(4));
      expect(healthyChecklist.healthyCount, equals(4));
      expect(healthyChecklist.allPassed, isTrue);

      final degradedView = PhoneMainViewConfig(
        isForegroundServiceRunning: false,
        isNotificationListenerGranted: false,
        isBatteryOptimizationIgnored: false,
        hasSmsPermission: false,
      );

      final degradedChecklist = degradedView.diagnosticsChecklist;
      expect(degradedChecklist.healthyCount, equals(0));
      expect(degradedChecklist.allPassed, isFalse);

      final fgsItem = degradedChecklist.items.firstWhere((i) => i.id == 'fgs');
      expect(fgsItem.status, equals('error'));
      expect(fgsItem.actionLabel, isNotNull);

      final nlsItem = degradedChecklist.items.firstWhere((i) => i.id == 'nls');
      expect(nlsItem.status, equals('warning'));
      expect(nlsItem.actionLabel, isNotNull);
    });

    test('supports localization switching for Russian and English', () {
      final viewRu = PhoneMainViewConfig(
        activeTab: PhoneTab.pairing,
        currentLocale: BridgeLocale.ru,
      );
      expect(viewRu.screenTitle, equals('Сканируйте QR-код'));

      final viewEn = viewRu.copyWith(
        currentLocale: BridgeLocale.en,
      );
      expect(viewEn.screenTitle, equals('Scan QR Code'));
    });
  });
}
