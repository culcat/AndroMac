import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'crypto_utils.dart';

/// Utilities for calculating, normalizing, and verifying X.509 certificate fingerprints.
class CertificateFingerprint {
  /// Computes the SHA-256 fingerprint of DER-encoded certificate bytes.
  static String compute(Uint8List derBytes, {bool colons = true}) {
    final digest = CryptoUtils.sha256(derBytes);
    return CryptoUtils.toHex(digest, colons: colons);
  }

  /// Normalizes a fingerprint string into lowercase hex without prefixes or delimiters.
  static String normalize(String fingerprint) {
    var clean = fingerprint.trim().toLowerCase();
    if (clean.startsWith('sha256:') || clean.startsWith('sha-256:')) {
      clean = clean.substring(clean.indexOf(':') + 1);
    }
    return clean.replaceAll(':', '').replaceAll(' ', '').replaceAll('-', '');
  }

  /// Verifies if a given certificate matches an expected fingerprint.
  static bool verify(Uint8List derBytes, String expectedFingerprint) {
    final computed = normalize(compute(derBytes, colons: false));
    final expected = normalize(expectedFingerprint);
    return CryptoUtils.fixedTimeEquals(computed, expected);
  }
}

/// Store and validator for pinned peer certificate fingerprints.
class CertificatePinStore {
  final Map<String, String> _pins = <String, String>{};

  /// Registers or updates a pinned certificate fingerprint for [deviceId].
  void pin(String deviceId, String fingerprint) {
    _pins[deviceId] = CertificateFingerprint.normalize(fingerprint);
  }

  /// Removes a pinned fingerprint for [deviceId].
  void unpin(String deviceId) {
    _pins.remove(deviceId);
  }

  /// Returns true if [deviceId] is currently pinned.
  bool isPinned(String deviceId) => _pins.containsKey(deviceId);

  /// Returns the normalized pinned fingerprint for [deviceId], or null if not found.
  String? getPin(String deviceId) => _pins[deviceId];

  /// Verifies peer certificate bytes against the pinned fingerprint for [deviceId].
  ///
  /// Throws [CertificatePinException] if verification fails or no pin exists.
  bool verifyCertificate(String deviceId, Uint8List derBytes) {
    final pinned = _pins[deviceId];
    if (pinned == null) {
      throw CertificatePinException('No pinned certificate found for device: $deviceId');
    }

    final computed = CertificateFingerprint.normalize(
      CertificateFingerprint.compute(derBytes, colons: false),
    );

    if (!CryptoUtils.fixedTimeEquals(computed, pinned)) {
      throw CertificatePinException(
        'Certificate pinning verification failed for device: $deviceId',
      );
    }

    return true;
  }

  /// Clears all pins (e.g. on full reset).
  void clear() => _pins.clear();
}

/// Exception thrown when certificate pinning verification fails.
class CertificatePinException implements Exception {
  final String message;
  const CertificatePinException(this.message);

  @override
  String toString() => 'CertificatePinException: $message';
}
