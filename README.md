# AndroMac (Bridge)

[![CI](https://github.com/culcat/AndroMac/actions/workflows/ci.yml/badge.svg)](https://github.com/culcat/AndroMac/actions/workflows/ci.yml)
[![Platform](https://img.shields.io/badge/platforms-Android%20%7C%20macOS-blue.svg)](https://github.com/culcat/AndroMac)
[![License](https://img.shields.io/badge/license-Apache%202.0%20%2F%20BSD-green.svg)](https://github.com/culcat/AndroMac)
[![Security](https://img.shields.io/badge/security-mTLS%20%2B%20Zero--Cloud-brightgreen.svg)](docs/threat_model.md)

**AndroMac** — это открытая, приватная и автономная (Local-First) система интеграции между устройствами **Android** и **macOS**. Проект воспроизводит бесшовный пользовательский опыт связки «iPhone + Mac» для пользователей Android, гарантируя полную конфиденциальность данных: **все операции выполняются строго по локальной сети (LAN) с шифрованием mTLS, без облачных серверов и учетных записей**.

---

## 🚀 Ключевые возможности

| Функция | Описание | Платформенная специфика |
| :--- | :--- | :--- |
| 📋 **Буфер обмена** | Мгновенная двусторонняя синхронизация буфера обмена с защитой от петель эха и фильтрацией паролей (Concealed / 1Password). | Автоматически Mac → Android. Для Android → Mac: плитка быстрых настроек (Quick Settings Tile) или системный Share Sheet (обход ограничений Android 10+). |
| 🔔 **Уведомления** | Зеркалирование входящих уведомлений смартфона в Notification Center на macOS в реальном времени. | Поддержка быстрых текстовых ответов прямо из уведомления на Mac (`RemoteInput` / `UNTextInputNotificationAction`) и двустороннее удаление. |
| 💬 **SMS-сообщения** | Полноценный настольный клиент для чтения диалогов и отправки SMS с Mac. | Поддержка выбора активного слота SIM-карты (Multi-SIM) и подтверждения доставки (`delivered`). |
| 🔐 **2FA / OTP коды** | Автоматическое извлечение 4–8 значных кодов подтверждения из SMS и push-уведомлений. | Автокопирование кода в буфер обмена macOS в один клик и нативный системный баннер с кодом. Поддержка шаблонов на русском и английском языках. |
| 🖥️ **Экран и ввод** | Просмотр экрана Android в окне Mac и управление с помощью мыши, трекпада и клавиатуры. | Работа через встроенный `scrcpy-server` + `adb` по Wi-Fi / USB без Root-прав. Нормализованный ввод (`[0.0, 1.0]`) и аппаратные кнопки (Back, Home, Recents). |
| 📁 **Передача файлов** | P2P-передача файлов любого размера между устройствами по локальной сети. | Потоковая передача чанками по 64 КиБ через WebSocket с валидацией целостности SHA-256. |
| 📱 **Статус и поиск** | Телеметрия заряда аккумулятора, статуса зарядки (`⚡`) и типа сети в меню-баре Mac. | Функция «Найти телефон» (Find My Phone) — запуск громкого звукового сигнала на телефоне прямо из трея Mac. |

---

## 🔒 Безопасность и архитектурные принципы

1. **Zero-Cloud & Privacy-First:**
   - Данные передаются напрямую между устройствами по локальной сети (LAN / Wi-Fi). Ни один байт содержимого не отправляется на сторонние серверы.
   - **Инвариант Zero-Log PII:** Тексты сообщений, контакты, коды 2FA/OTP и содержимое буфера обмена категорически запрещено логировать в `logcat`, `NSLog` или файлы журналов.
2. **Взаимный TLS (mTLS 1.3) и Certificate Pinning:**
   - Каждое устройство при первом запуске локально генерирует ключевую пару и самоподписанный X.509 сертификат (срок жизни 2 года).
   - Все соединения требуют взаимной аутентификации. Отпечатки сертификатов сопряженных пиров фиксируются в `CertificatePinStore` (Trust-On-First-Use).
3. **Сопряжение через QR-код и SAS-верификация:**
   - QR-код содержит идентификатор устройства, отпечаток сертификата и одноразовый секретный nonce (TTL 60 с).
   - На обоих экранах синхронно отображается 6-значный Short Authentication String (SAS) код (`123-456`) и последовательность из 4 графических эмодзи для исключения атак типа Man-in-the-Middle.
4. **Зашифрованное локальное хранилище:**
   - Кэш сообщений и история уведомлений шифруются на диске алгоритмом AES-256 через **SQLCipher** (Drift ORM).
   - Ключ шифрования защищен системными хранилищами: **macOS Keychain** и **Android KeyStore**.

---

## 📂 Структура монорепозитория

Проект организован как монорепозиторий Dart/Flutter с поддержкой Dart Pub Workspaces:

```text
AndroMac/
├── apps/
│   ├── desktop/                # macOS приложение (Flutter + Swift AppKit меню-бар Runner)
│   └── phone/                  # Android приложение (Flutter + Kotlin Foreground Services)
├── packages/
│   ├── bridge_protocol/        # Сетевой протокол, ULID-конверты, золотые схемы JSON
│   ├── bridge_crypto/          # Генерация X.509, mTLS, Certificate Pinning, QR и SAS
│   ├── bridge_transport/       # mDNS discovery, mTLS WebSockets, Heartbeat (15s), Backoff
│   ├── bridge_core/            # Реестр BridgeFeature, EventBus, хранилище BridgeStorage
│   ├── bridge_platform/        # Pigeon спецификации и платформенные интерфейсы Android/macOS
│   ├── bridge_ui/              # Дизайн-система, токены, компоненты и локализация (ru/en)
│   └── features/
│       ├── clipboard/          # Плагин синхронизации буфера с историей и подавлением эха
│       ├── notifications/      # Плагин зеркалирования и ответов на уведомления
│       ├── sms/                # Плагин SMS-диалогов и multi-SIM отправки
│       ├── device_status/      # Плагин телеметрии батареи и поиска телефона
│       ├── otp/                # Плагин эвристического извлечения 2FA/OTP кодов
│       ├── file_transfer/      # Плагин P2P передачи файлов с верификацией SHA-256
│       └── remote_control/     # Плагин управления экраном и нормализованного ввода
├── tools/
│   ├── fake_phone/             # CLI эмулятор Android устройства для разработки и CI
│   └── fake_mac/               # CLI эмулятор macOS контроллера для разработки и CI
└── docs/
    ├── threat_model.md         # Модель угроз v1 (STRIDE анализ, границы доверия)
    ├── adr/                    # Принятые архитектурные решения (ADR-001..004)
    ├── oem_troubleshooting.md  # Руководство по обходу ограничений вендоров (Xiaomi, Samsung)
    ├── risk_register.md        # Реестр рисков (R1-R10) с матрицей вероятностей и мер
    └── distribution.md         # Руководство по сборке, подписи, нотаризации и релизам
```

---

## 🛠️ Разработка и запуск

### Системные требования
- **Dart SDK:** 3.6.0+
- **Flutter SDK:** 3.27.0+ (с включенной поддержкой macOS desktop: `flutter config --enable-macos-desktop`)
- **macOS:** macOS 13+ (Ventura, Sonoma, Sequoia), Xcode 15+
- **Android:** Android SDK 26–35 (Java 17 / OpenJDK 17)

### Установка зависимостей
```bash
# Получение зависимостей во всех пакетах монорепозитория
dart pub get
```

### Запуск тестов и линтера
```bash
# Запуск всех тестов в монорепозитории
dart test

# Проверка форматирования кода
dart format --set-exit-if-changed .

# Статический анализ
flutter analyze
```

### Использование автономных CLI-эмуляторов для разработки
Для разработки функций без физических устройств доступны эмуляторы:

```bash
# Запуск эмулятора macOS контроллера на порту 8765
dart run tools/fake_mac/bin/fake_mac.dart --port 8765

# Запуск эмулятора Android смартфона с подключением к Mac
dart run tools/fake_phone/bin/fake_phone.dart --mac-host localhost --mac-port 8765
```

### Сборка приложений
```bash
# Сборка настольного приложения для macOS
flutter build macos --release

# Сборка Android APK с полным функционалом SMS (Direct distribution)
flutter build apk --flavor direct --release

# Сборка Android App Bundle для Google Play (Play compliant flavor)
flutter build appbundle --flavor play --release
```

---

## 📚 Архитектурная документация

- [Модель угроз и анализ STRIDE](docs/threat_model.md)
- [ADR-001: Криптография, mTLS, пиннинг сертификатов и сопряжение по QR/SAS](docs/adr/ADR-001-cryptography-and-pairing.md)
- [ADR-002: Фоновое выполнение на Android и безголовый FlutterEngine](docs/adr/ADR-002-android-background-execution.md)
- [ADR-003: Удаленное управление экраном Android с macOS](docs/adr/ADR-003-screen-remote-control.md)
- [ADR-004: Зашифрованное локальное хранилище на базе Drift и SQLCipher](docs/adr/ADR-004-encrypted-persistence.md)
- [Руководство по устранению неполадок фона вендоров (Xiaomi, Samsung, Huawei)](docs/oem_troubleshooting.md)
- [Реестр рисков и матрица смягчения](docs/risk_register.md)
- [Руководство по сборке, подписи, нотаризации и релизам](docs/distribution.md)

---

## 📄 Лицензии и авторские права

- Исходный код AndroMac распространяется под лицензией **Apache 2.0**.
- Сторонние компоненты: `scrcpy-server` (Apache 2.0), `adb` (Apache 2.0), `SQLCipher` (BSD-style), `Flutter/Dart` (BSD-3-Clause).
- Подробнее о требованиях лицензирования и авторских правах — в [Руководстве по дистрибуции](docs/distribution.md).
