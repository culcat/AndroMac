import 'dart:io';
import 'package:fake_mac/fake_mac.dart';

void main(List<String> args) async {
  print('====================================================');
  print('  AndroMac Synthetic macOS Controller Emulator (CLI) ');
  print('====================================================');

  var port = 8765;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? port;
    }
  }

  final controller = FakeMacController();
  print(
      'Starting Fake Mac Controller [${controller.name}] (ID: ${controller.deviceId})...');
  print('Listening for Android connections on port $port...');

  await controller.startServer(port: port);

  controller.onEvent.listen((envelope) {
    print('<- [Phone Event] Type: ${envelope.type} (id: ${envelope.id})');
    if (envelope.type == 'device.status') {
      final p = envelope.payload;
      print(
          '   Battery: ${p['batteryLevel']}%, Charging: ${p['isCharging']}, Net: ${p['networkType']}');
    } else if (envelope.type == 'sms.received') {
      final p = envelope.payload;
      print('   Incoming SMS from ${p['address']}: "${p['body']}"');
    } else if (envelope.type == 'notif.posted') {
      final p = envelope.payload;
      print(
          '   Notification from ${p['appName']}: [${p['title']}] "${p['text']}"');
    } else if (envelope.type == 'clipboard.update') {
      final p = envelope.payload;
      print('   Clipboard update: "${p['data']}"');
    }
  });

  print('Server ready! Waiting for Android phone or fake_phone to connect.');
  print('Press Ctrl+C to terminate.');

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down Fake Mac...');
    await controller.stop();
    exit(0);
  });
}
