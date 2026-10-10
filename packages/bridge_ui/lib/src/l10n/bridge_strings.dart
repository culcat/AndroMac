/// Abstract contract for localized UI strings in AndroMac.
abstract class BridgeStrings {
  // Common
  String get appName;
  String get appTagline;
  String get connected;
  String get disconnected;
  String get connecting;
  String get error;
  String get cancel;
  String get done;
  String get save;
  String get delete;
  String get copy;
  String get retry;

  // Pairing & Security
  String get scanQrCode;
  String get scanQrInstruction;
  String get sasTitle;
  String get sasInstruction;
  String get confirm;
  String get reject;
  String get codeExpired;

  // Features
  String get clipboard;
  String get copiedToClipboard;
  String get syncToMac;
  String get clipboardHistory;

  String get notifications;
  String get reply;
  String get dismiss;
  String get mirroringActive;

  String get messages;
  String get newMessage;
  String get typeMessage;
  String get sent;
  String get delivered;
  String get failedToSend;

  String get deviceStatus;
  String get batteryLevel;
  String get charging;
  String get findPhone;
  String get ringSignalSent;

  String get otpCopied;
  String get otpTitle;

  String get fileTransfer;
  String get sending;
  String get receiving;
  String get completed;

  String get remoteControl;
  String get streamActive;
  String get videoQuality;

  // Diagnostics
  String get diagnostics;
  String get localNetwork;
  String get foregroundService;
  String get notificationAccess;
  String get batteryOptimization;
  String get smsPermission;
  String get fixAction;
  String get allChecksPassed;
  String checksSummary(int passed, int total);
}
