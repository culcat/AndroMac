# AndroMac — Сборка, подпись, нотаризация и дистрибуция (Build & Distribution Guide)

## 1. Введение

Данный документ регламентирует процессы компиляции, криптографической подписи, нотаризации, создания установочных пакетов и публикации релизов **AndroMac** для платформ **macOS** и **Android** в соответствии с требованиями `bridge-development-plan.md` (§13).

---

## 2. Сборка и дистрибуция для macOS

Для обеспечения максимальной производительности (включая работу со встроенным `adb` и прямое связывание сокетов в локальной сети) приложение для macOS распространяется **вне Mac App Store** через прямую загрузку с сайта и GitHub Releases с обязательной нотаризацией от Apple.

### 2.1 Сертификаты и профили (Apple Developer)
Для подписания требуется учетная запись в Apple Developer Program:
- **Developer ID Application:** `Developer ID Application: Aleksandr Krainukov (TEAM_ID)` — подписание бинарных файлов и `.app` бандла.
- **Developer ID Installer:** `Developer ID Installer: Aleksandr Krainukov (TEAM_ID)` — подписание установочных `.pkg` пакетов (при необходимости).

### 2.2 Entitlements и Hardened Runtime
Приложение компилируется с обязательным включением **Hardened Runtime** (`--options runtime`).

Файл `apps/desktop/macos/Runner/Release.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Исходящие и входящие сетевые сокеты в локальной сети (mTLS WebSockets) -->
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <!-- Разрешение JIT компилятора для Flutter Engine -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
</dict>
</plist>
```

### 2.3 Скрипт сборки и нотаризации (CI / Release Automation)
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> 1. Сборка macOS релизного бандла..."
flutter build macos --release

APP_PATH="build/macos/Build/Products/Release/AndroMac.app"
DMG_PATH="build/macos/Build/Products/Release/AndroMac.dmg"

echo "==> 2. Подписание бандла сертификатом Developer ID..."
codesign --deep --force --verify --verbose \
  --options runtime \
  --entitlements apps/desktop/macos/Runner/Release.entitlements \
  --sign "Developer ID Application: Aleksandr Krainukov (${APPLE_TEAM_ID})" \
  "${APP_PATH}"

echo "==> 3. Создание DMG образа..."
create-dmg \
  --volname "AndroMac Installer" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "AndroMac.app" 175 190 \
  --app-drop-link 425 190 \
  "${DMG_PATH}" \
  "${APP_PATH}"

echo "==> 4. Нотаризация в Apple Notary Service..."
xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "notarytool-profile" \
  --wait

echo "==> 5. Прикрепление нотариального билета (Stapling)..."
xcrun stapler staple "${DMG_PATH}"

echo "==> Успешно! Файл готов к дистрибуции: ${DMG_PATH}"
```

### 2.4 Механизм автообновления (Sparkle)
Для фонового обновления macOS приложения без App Store интегрируется фреймворк **Sparkle 2**:
- Подпись обновлений выполняется с помощью EdDSA (ed25519) ключа.
- Манифест обновлений `appcast.xml` размещается на защищенном HTTPS-эндпоинте релизов GitHub.

---

## 3. Сборка и дистрибуция для Android

### 3.1 Архитектура Gradle Flavors (Два варианта сборки)

В соответствии с ограничениями политик Google Play (§4.3) реализовано разделение на две независимые версии:

| Параметр | Flavor `direct` | Flavor `play` |
| :--- | :--- | :--- |
| **Каналы дистрибуции** | GitHub Releases, официальный сайт, F-Droid | Google Play Store |
| **Разрешения SMS** | `READ_SMS`, `RECEIVE_SMS`, `SEND_SMS` включены | Полностью исключены |
| **Функционал** | Полный: SMS диалоги, отправка с Mac, авточтение OTP | Буфер обмена, уведомления, файлы, удаленный экран |
| **Application ID** | `com.andromac.bridge` | `com.andromac.bridge.play` |
| **Команда сборки** | `flutter build apk --flavor direct` | `flutter build appbundle --flavor play` |

### 3.2 Подписание релизного APK / AAB
Параметры подписи хранятся в защищенном файле `apps/phone/android/key.properties`:
```properties
storePassword=SECURE_KEYSTORE_PASSWORD
keyPassword=SECURE_KEY_PASSWORD
keyAlias=andromac-key-alias
storeFile=/path/to/andromac-release.keystore
```

Конфигурация в `apps/phone/android/app/build.gradle`:
```groovy
signingConfigs {
    release {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = file(keystoreProperties['storeFile'])
            storePassword = keystoreProperties['storePassword']
        }
    }
}
```

### 3.3 Google Play Data Safety (Декларация безопасности данных)
Для версии `play`:
- **Сбор данных:** Никакие персональные данные (содержимое буфера, тексты уведомлений, файлы) **НЕ** собираются и **НЕ** передаются третьим лицам.
- **Шифрование при передаче:** Все данные шифруются в локальной сети по протоколу mTLS (TLS 1.3).
- **Удаление данных:** Пользователь может в любой момент удалить всю локальную историю через настройки приложения или отвязав устройство.

---

## 4. Сторонние лицензии и соответствие требованиям (Third-Party Compliance)

Проект использует открытые компоненты со следующими обязательными лицензионными требованиями:

1. **scrcpy-server & adb:**
   - Лицензия: **Apache License 2.0**.
   - Требование: Сохранение уведомления об авторских правах и текста лицензии Apache 2.0 в дистрибутиве (`About / Licenses`).
2. **SQLCipher:**
   - Лицензия: **BSD-style License** (Zetetic LLC).
   - Требование: Сохранение уведомления об авторских правах Zetetic LLC.
3. **Flutter & Dart Packages (Riverpod, Drift, Pigeon, Meta):**
   - Лицензия: **BSD-3-Clause / MIT**.
   - Требование: Полная совместимость с коммерческим и открытым распространением.

---

## 5. Контрольный чек-лист релизной сборки (Release Checklist)

Перед публикацией релиза v1.0.0:
- [ ] Все unit и контрактные тесты пройдены (`dart test`).
- [ ] Линтер не выдает предупреждений (`flutter analyze`).
- [ ] `docs/threat_model.md` и ADR-001..004 актуализированы.
- [ ] Бандл macOS успешно нотаризован в Apple (`notarytool submit` -> `Accepted`).
- [ ] APK `direct` подписан релизным ключом и протестирован на Android 10, 13, 14, 15.
- [ ] AAB `play` успешно проходит валидацию Google Play Console.
- [ ] Файл лицензий `LICENSE` и открытые уведомления сторонних библиотек включены в сборки.
