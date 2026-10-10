import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bridge_platform/bridge_platform.dart';
import 'package:andromac_phone/phone_app.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const AndroMacPhoneApp());

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down AndroMac Phone Controller...');
    await controller.stop();
    exit(0);
  });
}

class AndroMacPhoneApp extends StatelessWidget {
  const AndroMacPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndroMac',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('AndroMac')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android, size: 64, color: Colors.greenAccent),
              SizedBox(height: 16),
              Text(
                'AndroMac Mobile Service Active',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Foreground Service & mTLS listening',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
