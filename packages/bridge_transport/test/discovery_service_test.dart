import 'package:test/test.dart';
import 'package:bridge_transport/bridge_transport.dart';

void main() {
  group('DiscoveryService and BridgeServiceInfo', () {
    test('BridgeServiceInfo parses and formats mDNS TXT records', () {
      final info = BridgeServiceInfo(
        deviceId: 'mac-101',
        name: 'MacBook Pro',
        host: '192.168.1.55',
        port: 8765,
        fingerprint: 'aabbccdd',
        protocolVersion: 1,
      );

      final txt = info.toTxtRecords();
      expect(txt['id'], equals('mac-101'));
      expect(txt['fp'], equals('aabbccdd'));
      expect(txt['v'], equals('1'));

      final fromTxt = BridgeServiceInfo.fromTxtRecords(
        host: '192.168.1.55',
        port: 8765,
        name: 'MacBook Pro',
        txt: txt,
      );

      expect(fromTxt.deviceId, equals(info.deviceId));
      expect(fromTxt.name, equals(info.name));
      expect(fromTxt.host, equals(info.host));
      expect(fromTxt.port, equals(info.port));
      expect(fromTxt.fingerprint, equals(info.fingerprint));
    });

    test('InMemoryDiscoveryService broadcasts and receives simulated peers', () async {
      final service = InMemoryDiscoveryService();
      final peer = BridgeServiceInfo(
        deviceId: 'phone-202',
        name: 'Pixel 8',
        host: '192.168.1.88',
        port: 8765,
        fingerprint: '11223344',
      );

      final events = <BridgeServiceInfo>[];
      final subscription = service.startDiscovery().listen(events.add);

      service.simulateFoundPeer(peer);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events.length, equals(1));
      expect(events.first.deviceId, equals('phone-202'));
      expect(events.first.name, equals('Pixel 8'));

      await subscription.cancel();
      service.dispose();
    });
  });
}
