import 'package:test/test.dart';
import 'package:bridge_ui/bridge_ui.dart';

void main() {
  group('BridgeL10n & Localized Strings', () {
    test('BridgeStringsRu provides complete Russian translations', () {
      const ru = BridgeStringsRu();

      expect(ru.appName, equals('AndroMac'));
      expect(ru.connected, equals('Подключено'));
      expect(ru.disconnected, equals('Отключено'));
      expect(ru.scanQrCode, equals('Сканируйте QR-код'));
      expect(ru.clipboard, equals('Буфер обмена'));
      expect(ru.notifications, equals('Уведомления'));
      expect(ru.messages, equals('Сообщения'));
      expect(ru.deviceStatus, equals('Статус устройства'));
      expect(ru.findPhone, contains('Найти телефон'));
      expect(ru.fileTransfer, equals('Передача файлов'));
      expect(ru.remoteControl, equals('Управление экраном'));
      expect(ru.diagnostics, equals('Диагностика'));
      expect(ru.checksSummary(3, 5), equals('3/5 проверок пройдено'));
    });

    test('BridgeStringsEn provides complete English translations', () {
      const en = BridgeStringsEn();

      expect(en.appName, equals('AndroMac'));
      expect(en.connected, equals('Connected'));
      expect(en.disconnected, equals('Disconnected'));
      expect(en.scanQrCode, equals('Scan QR Code'));
      expect(en.clipboard, equals('Clipboard'));
      expect(en.notifications, equals('Notifications'));
      expect(en.messages, equals('Messages'));
      expect(en.deviceStatus, equals('Device Status'));
      expect(en.findPhone, contains('Find My Phone'));
      expect(en.fileTransfer, equals('File Transfer'));
      expect(en.remoteControl, equals('Screen Control'));
      expect(en.diagnostics, equals('Diagnostics'));
      expect(en.checksSummary(4, 5), equals('4/5 checks passed'));
    });

    test('BridgeL10n manages locale switching and resolution', () {
      // Default locale is ru
      BridgeL10n.setLocale(BridgeLocale.ru);
      expect(BridgeL10n.currentLocale, equals(BridgeLocale.ru));
      expect(BridgeL10n.strings.connected, equals('Подключено'));

      // Switch to en
      BridgeL10n.setLocale(BridgeLocale.en);
      expect(BridgeL10n.currentLocale, equals(BridgeLocale.en));
      expect(BridgeL10n.strings.connected, equals('Connected'));

      // Reset back to ru
      BridgeL10n.setLocale(BridgeLocale.ru);
      expect(BridgeL10n.strings.connected, equals('Подключено'));

      // Language code resolution
      expect(BridgeL10n.fromLanguageCode('en'), equals(BridgeLocale.en));
      expect(BridgeL10n.fromLanguageCode('en_US'), equals(BridgeLocale.en));
      expect(BridgeL10n.fromLanguageCode('en-GB'), equals(BridgeLocale.en));
      expect(BridgeL10n.fromLanguageCode('ru'), equals(BridgeLocale.ru));
      expect(BridgeL10n.fromLanguageCode('ru_RU'), equals(BridgeLocale.ru));
      expect(BridgeL10n.fromLanguageCode(null), equals(BridgeLocale.ru));
      expect(BridgeL10n.fromLanguageCode('fr'), equals(BridgeLocale.ru));
    });
  });
}
