import 'package:test/test.dart';
import 'package:bridge_crypto/bridge_crypto.dart';

void main() {
  group('BridgePairingData', () {
    test('create generates valid pairing data with default TTL', () {
      final now = 1760000000000;
      final data = BridgePairingData.create(
        deviceId: 'mac-studio-1',
        name: 'Alex Mac Studio',
        ips: ['192.168.1.100'],
        port: 8765,
        fingerprint: 'AA:BB:CC:DD',
        ttlSeconds: 120,
        nowMs: now,
      );

      expect(data.deviceId, equals('mac-studio-1'));
      expect(data.name, equals('Alex Mac Studio'));
      expect(data.ips, equals(['192.168.1.100']));
      expect(data.port, equals(8765));
      expect(data.fingerprint, equals('aabbccdd'));
      expect(data.pairingCode.length, equals(6));
      expect(data.expiresAt, equals(now + 120000));
      expect(data.isExpired(now + 119000), isFalse);
      expect(data.isExpired(now + 121000), isTrue);
    });

    test('serializes and deserializes from JSON correctly', () {
      final data = BridgePairingData(
        v: 1,
        deviceId: 'mac-1',
        name: 'Mac',
        ips: ['192.168.1.50'],
        port: 8765,
        fingerprint: '1234abcd',
        pairingCode: '654321',
        expiresAt: 1760000120000,
      );

      final json = data.encodeJson();
      final decoded = BridgePairingData.decode(json);

      expect(decoded.deviceId, equals(data.deviceId));
      expect(decoded.name, equals(data.name));
      expect(decoded.ips, equals(data.ips));
      expect(decoded.port, equals(data.port));
      expect(decoded.fingerprint, equals(data.fingerprint));
      expect(decoded.pairingCode, equals(data.pairingCode));
      expect(decoded.expiresAt, equals(data.expiresAt));
    });

    test('serializes and deserializes from andromac://pair URI', () {
      final data = BridgePairingData(
        v: 1,
        deviceId: 'phone-pixel-8',
        name: 'Pixel 8',
        ips: ['192.168.1.120'],
        port: 8765,
        fingerprint: 'abcd1234',
        pairingCode: '998877',
        expiresAt: 1760000120000,
      );

      final uri = data.encodeUri();
      expect(uri, startsWith('andromac://pair?data='));

      final decoded = BridgePairingData.decode(uri);
      expect(decoded.deviceId, equals('phone-pixel-8'));
      expect(decoded.pairingCode, equals('998877'));
      expect(decoded.fingerprint, equals('abcd1234'));
    });
  });
}
