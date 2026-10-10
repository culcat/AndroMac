import 'bridge_strings.dart';

/// Russian localization implementation of [BridgeStrings].
class BridgeStringsRu implements BridgeStrings {
  const BridgeStringsRu();

  @override
  String get appName => 'AndroMac';

  @override
  String get appTagline => 'Локальная синхронизация Android и macOS';

  @override
  String get connected => 'Подключено';

  @override
  String get disconnected => 'Отключено';

  @override
  String get connecting => 'Подключение...';

  @override
  String get error => 'Ошибка';

  @override
  String get cancel => 'Отмена';

  @override
  String get done => 'Готово';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get copy => 'Копировать';

  @override
  String get retry => 'Повторить';

  @override
  String get scanQrCode => 'Сканируйте QR-код';

  @override
  String get scanQrInstruction =>
      'Откройте AndroMac на телефоне и наведите камеру на QR-код на экране Mac.';

  @override
  String get sasTitle => 'Код подтверждения (SAS)';

  @override
  String get sasInstruction =>
      'Убедитесь, что одноразовые коды и эмодзи на обоих экранах совпадают.';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get reject => 'Отклонить';

  @override
  String get codeExpired => 'Срок действия кода сопряжения истек';

  @override
  String get clipboard => 'Буфер обмена';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get syncToMac => 'Синхронизировать с Mac';

  @override
  String get clipboardHistory => 'История буфера обмена';

  @override
  String get notifications => 'Уведомления';

  @override
  String get reply => 'Ответить';

  @override
  String get dismiss => 'Закрыть';

  @override
  String get mirroringActive => 'Зеркалирование уведомлений активно';

  @override
  String get messages => 'Сообщения';

  @override
  String get newMessage => 'Новое сообщение';

  @override
  String get typeMessage => 'Введите текст сообщения...';

  @override
  String get sent => 'Отправлено';

  @override
  String get delivered => 'Доставлено';

  @override
  String get failedToSend => 'Не удалось отправить сообщение';

  @override
  String get deviceStatus => 'Статус устройства';

  @override
  String get batteryLevel => 'Заряд батареи';

  @override
  String get charging => 'Заряжается';

  @override
  String get findPhone => 'Найти телефон 🔔';

  @override
  String get ringSignalSent => 'Звуковой сигнал отправлен на телефон';

  @override
  String get otpCopied => 'Код подтверждения скопирован в буфер обмена';

  @override
  String get otpTitle => 'Код 2FA / OTP';

  @override
  String get fileTransfer => 'Передача файлов';

  @override
  String get sending => 'Отправка...';

  @override
  String get receiving => 'Получение...';

  @override
  String get completed => 'Завершено';

  @override
  String get remoteControl => 'Управление экраном';

  @override
  String get streamActive => 'Трансляция экрана активна';

  @override
  String get videoQuality => 'Качество видео';

  @override
  String get diagnostics => 'Диагностика';

  @override
  String get localNetwork => 'Локальная сеть';

  @override
  String get foregroundService => 'Фоновая служба';

  @override
  String get notificationAccess => 'Доступ к уведомлениям';

  @override
  String get batteryOptimization => 'Исключение из оптимизации батареи';

  @override
  String get smsPermission => 'Разрешение SMS';

  @override
  String get fixAction => 'Исправить';

  @override
  String get allChecksPassed => 'Все проверки успешно пройдены';

  @override
  String checksSummary(int passed, int total) =>
      '$passed/$total проверок пройдено';
}
