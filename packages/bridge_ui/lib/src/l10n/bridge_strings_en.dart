import 'bridge_strings.dart';

/// English localization implementation of [BridgeStrings].
class BridgeStringsEn implements BridgeStrings {
  const BridgeStringsEn();

  @override
  String get appName => 'AndroMac';

  @override
  String get appTagline => 'Local sync between Android and macOS';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get connecting => 'Connecting...';

  @override
  String get error => 'Error';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get retry => 'Retry';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get scanQrInstruction =>
      'Open AndroMac on your phone and point the camera at the QR code on your Mac screen.';

  @override
  String get sasTitle => 'Verification Code (SAS)';

  @override
  String get sasInstruction =>
      'Confirm that the one-time code and emoji sequence match on both screens.';

  @override
  String get confirm => 'Confirm';

  @override
  String get reject => 'Reject';

  @override
  String get codeExpired => 'Pairing code has expired';

  @override
  String get clipboard => 'Clipboard';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get syncToMac => 'Sync to Mac';

  @override
  String get clipboardHistory => 'Clipboard History';

  @override
  String get notifications => 'Notifications';

  @override
  String get reply => 'Reply';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get mirroringActive => 'Notification mirroring active';

  @override
  String get messages => 'Messages';

  @override
  String get newMessage => 'New Message';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get sent => 'Sent';

  @override
  String get delivered => 'Delivered';

  @override
  String get failedToSend => 'Failed to send message';

  @override
  String get deviceStatus => 'Device Status';

  @override
  String get batteryLevel => 'Battery Level';

  @override
  String get charging => 'Charging';

  @override
  String get findPhone => 'Find My Phone 🔔';

  @override
  String get ringSignalSent => 'Ring alert sent to phone';

  @override
  String get otpCopied => 'Verification code copied to clipboard';

  @override
  String get otpTitle => '2FA / OTP Code';

  @override
  String get fileTransfer => 'File Transfer';

  @override
  String get sending => 'Sending...';

  @override
  String get receiving => 'Receiving...';

  @override
  String get completed => 'Completed';

  @override
  String get remoteControl => 'Screen Control';

  @override
  String get streamActive => 'Screen streaming active';

  @override
  String get videoQuality => 'Video Quality';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get localNetwork => 'Local Network';

  @override
  String get foregroundService => 'Foreground Service';

  @override
  String get notificationAccess => 'Notification Access';

  @override
  String get batteryOptimization => 'Battery Optimization Exemption';

  @override
  String get smsPermission => 'SMS Permission';

  @override
  String get fixAction => 'Fix';

  @override
  String get allChecksPassed => 'All checks passed successfully';

  @override
  String checksSummary(int passed, int total) => '$passed/$total checks passed';
}
