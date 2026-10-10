import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:bridge_crypto/bridge_crypto.dart';

void main() {
  group('CertificatePin and CryptoUtils', () {
    test('CryptoUtils.sha256 computes correct standard digest', () {
      // Test vector: SHA-256("hello world")
      final input = Uint8List.fromList(utf8.encode('hello world'));
      final digest = CryptoUtils.sha256(input);
      final hex = CryptoUtils.toHex(digest);

      expect(
          hex,
          equals(
              'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9'));
    });

    test('CertificateFingerprint computes and normalizes fingerprints', () {
      final certBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      final fpWithColons =
          CertificateFingerprint.compute(certBytes, colons: true);
      expect(fpWithColons, contains(':'));

      final normalized = CertificateFingerprint.normalize(fpWithColons);
      expect(normalized, isNot(contains(':')));
      expect(normalized.length, equals(64));

      final prefixed = 'SHA256:AA:BB:CC:DD';
      expect(CertificateFingerprint.normalize(prefixed), equals('aabbccdd'));
    });

    test('CertificatePinStore pins and verifies certificates', () {
      final store = CertificatePinStore();
      final deviceId = 'android-phone-1';
      final certBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      final fp = CertificateFingerprint.compute(certBytes);

      store.pin(deviceId, fp);
      expect(store.isPinned(deviceId), isTrue);
      expect(store.verifyCertificate(deviceId, certBytes), isTrue);

      final fakeCert = Uint8List.fromList([99, 99, 99]);
      expect(
        () => store.verifyCertificate(deviceId, fakeCert),
        throwsA(isA<CertificatePinException>()),
      );

      store.unpin(deviceId);
      expect(store.isPinned(deviceId), isFalse);
      expect(
        () => store.verifyCertificate(deviceId, certBytes),
        throwsA(isA<CertificatePinException>()),
      );
    });

    test('CryptoUtils.fixedTimeEquals compares strings safely', () {
      expect(CryptoUtils.fixedTimeEquals('secret', 'secret'), isTrue);
      expect(CryptoUtils.fixedTimeEquals('secret', 'secret2'), isFalse);
      expect(CryptoUtils.fixedTimeEquals('secret', 'secreT'), isFalse);
    });

    test('CryptoUtils.generateNumericOtp produces exact digits', () {
      final otp6 = CryptoUtils.generateNumericOtp(6);
      expect(otp6.length, equals(6));
      expect(int.tryParse(otp6), isNotNull);

      final otp8 = CryptoUtils.generateNumericOtp(8);
      expect(otp8.length, equals(8));
    });
  });
}
