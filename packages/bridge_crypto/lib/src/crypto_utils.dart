import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as p_crypto;

/// Cryptographic utility functions for hashing, random generation, and constant-time checks.
class CryptoUtils {
  /// Computes the standard SHA-256 digest of input bytes.
  static Uint8List sha256(Uint8List data) {
    final digest = p_crypto.sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Computes SHA-256 digest of a UTF-8 string.
  static Uint8List sha256String(String input) {
    return sha256(Uint8List.fromList(utf8.encode(input)));
  }

  /// Formats bytes as a lowercase hex string.
  static String toHex(Uint8List bytes, {bool colons = false}) {
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      if (colons && i > 0) buffer.write(':');
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString().toLowerCase();
  }

  /// Parses a hex string into a Uint8List, ignoring colons and case.
  static Uint8List fromHex(String hex) {
    final clean = hex.replaceAll(':', '').replaceAll(' ', '').toLowerCase();
    if (clean.length % 2 != 0) {
      throw FormatException('Invalid hex string length: $hex');
    }
    final result = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Compares two strings in constant time to prevent timing attacks.
  static bool fixedTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Compares two byte lists in constant time.
  static bool fixedTimeEqualsBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Generates cryptographically secure random bytes using [Random.secure].
  static Uint8List secureRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Generates a numeric one-time password of specified [digits] length.
  static String generateNumericOtp([int digits = 6]) {
    final random = Random.secure();
    final max = pow(10, digits).toInt();
    final value = random.nextInt(max);
    return value.toString().padLeft(digits, '0');
  }
}
