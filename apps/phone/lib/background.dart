import 'package:bridge_platform/bridge_platform.dart';
import 'package:andromac_phone/phone_app.dart';

/// Headless entry point invoked by Android [BridgeForegroundService] via [FlutterEngine].
/// Runs continuously in the background to sustain mTLS WebSockets, event routing,
/// and native platform channel messaging without requiring an active UI window.
@pragma('vm:entry-point')
void backgroundMain() async {
  final controller = PhoneAppController(
    deviceName: 'Android Device (Background)',
    platform: AndroidBridgePlatform.instance,
  );

  await controller.startService();
}
