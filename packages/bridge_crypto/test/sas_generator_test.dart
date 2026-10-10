import 'package:test/test.dart';
import 'package:bridge_crypto/bridge_crypto.dart';

void main() {
  group('SasGenerator', () {
    test('produces identical SAS code regardless of fingerprint order', () {
      final fp1 = 'AA:BB:CC:DD:EE:FF';
      final fp2 = '11:22:33:44:55:66';
      final pairingCode = '123456';

      final sas1 = SasGenerator.compute(
        fingerprintA: fp1,
        fingerprintB: fp2,
        pairingCode: pairingCode,
      );

      final sas2 = SasGenerator.compute(
        fingerprintA: fp2,
        fingerprintB: fp1,
        pairingCode: pairingCode,
      );

      expect(sas1.numericCode, equals(sas2.numericCode));
      expect(sas1.emojiCode, equals(sas2.emojiCode));
      expect(sas1.numericCode.length,
          equals(7)); // format: XXX-XXX (6 digits + hyphen)
      expect(sas1.numericCode, contains('-'));
      expect(sas1.emojiList.length, equals(4)); // 4 visual emojis
    });

    test('changes SAS code when pairing code differs', () {
      final fp1 = 'AA:BB:CC:DD';
      final fp2 = '11:22:33:44';

      final sas1 = SasGenerator.compute(
        fingerprintA: fp1,
        fingerprintB: fp2,
        pairingCode: '111111',
      );

      final sas2 = SasGenerator.compute(
        fingerprintA: fp1,
        fingerprintB: fp2,
        pairingCode: '222222',
      );

      expect(sas1.numericCode, isNot(equals(sas2.numericCode)));
    });
  });
}
