import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:andromac_desktop/desktop_app.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const AndroMacDesktopApp());

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down AndroMac Desktop Controller...');
    await controller.stop();
    exit(0);
  });
}

class AndroMacDesktopApp extends StatelessWidget {
  const AndroMacDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndroMac',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('AndroMac (Bridge)')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.devices, size: 64, color: Colors.blueAccent),
              SizedBox(height: 16),
              Text(
                'AndroMac Desktop is Running',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Status: Listening for Android peer in local network (mTLS)',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
