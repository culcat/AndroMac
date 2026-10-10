import 'dart:async';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:fake_phone/fake_phone.dart';

void main(List<String> args) async {
  print('====================================================');
  print('  AndroMac Synthetic Android Phone Emulator (CLI)   ');
  print('====================================================');

  final device = FakePhoneDevice();
  print('Starting Fake Phone [${device.name}] (ID: ${device.deviceId})...');

  var host = '127.0.0.1';
  var port = 8765;

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--mac-host' && i + 1 < args.length) {
      host = args[i + 1];
    } else if (args[i] == '--mac-port' && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? port;
    }
  }

  print('Connecting to Mac at ws://$host:$port...');

  try {
    final channel = await BridgeClient.connect(
      Uri.parse('ws://$host:$port'),
      timeout: const Duration(seconds: 5),
    );

    await device.attach(channel);
    print('Connected and handshaked with Mac controller successfully!');

    // Send initial status
    device.sendBatteryStatus(batteryLevel: 92, isCharging: true);
    print('-> Sent battery status (92%, charging)');

    // Listen for events from Mac
    device.onEvent.listen((envelope) {
      print('<- Received from Mac: [${envelope.type}] (id: ${envelope.id})');
    });

    // Send sample SMS after 2 seconds
    Timer(const Duration(seconds: 2), () {
      device.sendSms(
        address: '+1 (555) 019-2834',
        body: 'Hey Alex, your verification code is 849201.',
      );
      print('-> Sent incoming SMS from +1 (555) 019-2834');
    });

    // Send sample Notification after 4 seconds
    Timer(const Duration(seconds: 4), () {
      device.sendNotification(
        appName: 'WhatsApp',
        packageName: 'com.whatsapp',
        title: 'Work Group',
        text: 'The deploy was successful!',
      );
      print('-> Sent notification from WhatsApp');
    });

    // Send sample clipboard after 6 seconds
    Timer(const Duration(seconds: 6), () {
      device.sendClipboard('https://github.com/culcat/AndroMac');
      print('-> Sent clipboard update');
    });
  } catch (e) {
    print('Could not connect to Mac: $e');
    print('You can run this once the Mac app or server is active.');
  }
}
