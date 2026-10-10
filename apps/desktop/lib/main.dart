import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:andromac_desktop/desktop_app.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  print('====================================================');
  print('     AndroMac macOS Desktop Controller (Engine)     ');
  print('====================================================');

  final mockPlatform = MockMacOsPlatform();
  final controller = DesktopAppController(
    deviceName: 'Alex MacBook Pro',
    port: 8765,
    platform: mockPlatform,
  );

  print('Starting Desktop Controller for [${controller.deviceName}]...');
  print('Device ID: ${controller.localDeviceId}');

  await controller.start();
  print(
      'Listening for Android connections on port ${controller.server.boundPort}...');

  controller.onStatusChanged.listen((status) {
    print(
        '[Status Update] State: ${status.state.name}, Peer: ${status.peerDeviceId ?? "none"}');
  });

  print('Desktop Controller operational.');
  print('Press Ctrl+C to terminate.');

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down AndroMac Desktop Controller...');
    await controller.stop();
    exit(0);
  });
}
