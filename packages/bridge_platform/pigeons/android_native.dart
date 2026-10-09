// Pigeon schema definition for Android Kotlin platform channels.
// Run with: dart run pigeon --input pigeons/android_native.dart

class PigeonNotification {
  String key;
  String packageName;
  String appName;
  String title;
  String text;
  int postTime;
  bool canReply;

  PigeonNotification({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postTime,
    required this.canReply,
  });
}

class PigeonSms {
  String address;
  String body;
  int simSlot;
  String? clientMessageId;

  PigeonSms({
    required this.address,
    required this.body,
    required this.simSlot,
    this.clientMessageId,
  });
}

class PigeonBattery {
  int level;
  bool isCharging;
  bool isDnd;

  PigeonBattery({
    required this.level,
    required this.isCharging,
    required this.isDnd,
  });
}

/// Host API implemented by Android Kotlin native services.
abstract class AndroidHostApi {
  void startForegroundService();
  void stopForegroundService();
  bool sendSms(PigeonSms sms);
  void copyToClipboard(String text);
  void openNotificationListenerSettings();
  void requestIgnoreBatteryOptimizations();
  PigeonBattery getBatteryStatus();
}

/// Flutter API called from Android Kotlin services into the Flutter engine.
abstract class AndroidFlutterApi {
  void onNotificationPosted(PigeonNotification notification);
  void onNotificationDismissed(String key);
  void onSmsReceived(PigeonSms sms);
  void onClipboardCaptured(String text);
  void onBatteryChanged(PigeonBattery battery);
}
