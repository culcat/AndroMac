import 'bridge_strings.dart';
import 'bridge_strings_ru.dart';
import 'bridge_strings_en.dart';

/// Supported locales in AndroMac.
enum BridgeLocale {
  ru('Русский', 'ru'),
  en('English', 'en');

  final String displayName;
  final String languageCode;

  const BridgeLocale(this.displayName, this.languageCode);
}

/// Central localization manager providing access to translated strings and formatters.
class BridgeL10n {
  static const BridgeStringsRu _ru = BridgeStringsRu();
  static const BridgeStringsEn _en = BridgeStringsEn();

  static BridgeLocale _currentLocale = BridgeLocale.ru;

  /// Currently active locale.
  static BridgeLocale get currentLocale => _currentLocale;

  /// Changes the globally active locale.
  static void setLocale(BridgeLocale locale) {
    _currentLocale = locale;
  }

  /// Active string bundle for the current locale.
  static BridgeStrings get strings => forLocale(_currentLocale);

  /// Retrieves strings for a specific [BridgeLocale].
  static BridgeStrings forLocale(BridgeLocale locale) {
    switch (locale) {
      case BridgeLocale.ru:
        return _ru;
      case BridgeLocale.en:
        return _en;
    }
  }

  /// Resolves [BridgeLocale] from a language code (e.g. 'ru', 'en_US'), defaulting to [BridgeLocale.ru].
  static BridgeLocale fromLanguageCode(String? code) {
    if (code == null) return BridgeLocale.ru;
    final lower = code.toLowerCase();
    if (lower.startsWith('en')) return BridgeLocale.en;
    return BridgeLocale.ru;
  }
}
