import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:andromac_phone/phone_app.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  print('====================================================');
  print('     AndroMac Android Phone Controller (Engine)     ');
  print('====================================================');

  final mockPlatform = MockAndroidPlatform();
  final controller = PhoneAppController(
    deviceName: 'Google Pixel 8 Pro',
    platform: mockPlatform,
  );

  print('Starting Phone Controller for [${controller.deviceName}]...');
  print('Device ID: ${controller.localDeviceId}');

  await controller.startService(port: 8765);
  print('Phone service running and ready for connection.');

  controller.onStatusChanged.listen((status) {
    print(
        '[Status Update] State: ${status.state.name}, Peer: ${status.peerDeviceId ?? "none"}');
  });

  controller.onRingAlert.listen((reason) {
    print('>>> [FIND MY PHONE] Ring alert triggered! Reason: $reason <<<');
  });

  print('Android Phone Controller operational.');
  print('Press Ctrl+C to terminate.');

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down AndroMac Phone Controller...');
    await controller.stop();
    exit(0);
  });
}
