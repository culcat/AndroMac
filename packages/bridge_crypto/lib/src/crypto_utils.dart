import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Cryptographic utility functions for hashing, random generation, and constant-time checks.
class CryptoUtils {
  /// Computes the standard SHA-256 digest of input bytes.
  static Uint8List sha256(Uint8List data) {
    return _Sha256().update(data).digest();
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
  static bool fixedTimeBytesEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Generates cryptographically secure random bytes.
  static Uint8List randomBytes(int length) {
    final rng = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return bytes;
  }

  /// Generates a numeric one-time pairing code (e.g., 6 digits).
  static String generateNumericOtp([int digits = 6]) {
    final rng = Random.secure();
    final max = pow(10, digits).toInt();
    final number = rng.nextInt(max);
    return number.toString().padLeft(digits, '0');
  }
}

/// Standalone FIPS 180-4 SHA-256 implementation in pure Dart.
class _Sha256 {
  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  ];

  int _h0 = 0x6a09e667;
  int _h1 = 0xbb67ae85;
  int _h2 = 0x3c6ef372;
  int _h3 = 0xa54ff53a;
  int _h4 = 0x510e527f;
  int _h5 = 0x9b05688c;
  int _h6 = 0x1f83d9ab;
  int _h7 = 0x5be0cd19;

  final Uint8List _buffer = Uint8List(64);
  int _bufferLength = 0;
  int _totalBytes = 0;

  _Sha256 update(Uint8List data) {
    _totalBytes += data.length;
    var offset = 0;
    while (offset < data.length) {
      final toCopy = min(data.length - offset, 64 - _bufferLength);
      _buffer.setRange(_bufferLength, _bufferLength + toCopy, data, offset);
      _bufferLength += toCopy;
      offset += toCopy;

      if (_bufferLength == 64) {
        _processBlock(_buffer);
        _bufferLength = 0;
      }
    }
    return this;
  }

  Uint8List digest() {
    // Padding
    final totalBits = _totalBytes * 8;
    _buffer[_bufferLength++] = 0x80;

    if (_bufferLength > 56) {
      _buffer.fillRange(_bufferLength, 64, 0);
      _processBlock(_buffer);
      _bufferLength = 0;
    }

    _buffer.fillRange(_bufferLength, 56, 0);
    final view = ByteData.view(_buffer.buffer);
    // 64-bit big endian length
    view.setUint32(56, (totalBits >> 32) & 0xffffffff, Endian.big);
    view.setUint32(60, totalBits & 0xffffffff, Endian.big);
    _processBlock(_buffer);

    final out = Uint8List(32);
    final outView = ByteData.view(out.buffer);
    outView.setUint32(0, _h0, Endian.big);
    outView.setUint32(4, _h1, Endian.big);
    outView.setUint32(8, _h2, Endian.big);
    outView.setUint32(12, _h3, Endian.big);
    outView.setUint32(16, _h4, Endian.big);
    outView.setUint32(20, _h5, Endian.big);
    outView.setUint32(24, _h6, Endian.big);
    outView.setUint32(28, _h7, Endian.big);
    return out;
  }

  void _processBlock(Uint8List block) {
    final w = Int32List(64);
    final view = ByteData.view(block.buffer, block.offsetInBytes, 64);
    for (var i = 0; i < 16; i++) {
      w[i] = view.getUint32(i * 4, Endian.big);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }

    var a = _h0;
    var b = _h1;
    var c = _h2;
    var d = _h3;
    var e = _h4;
    var f = _h5;
    var g = _h6;
    var h = _h7;

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e) & g);
      final temp1 = (h + s1 + ch + _k[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xffffffff;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xffffffff;
    }

    _h0 = (_h0 + a) & 0xffffffff;
    _h1 = (_h1 + b) & 0xffffffff;
    _h2 = (_h2 + c) & 0xffffffff;
    _h3 = (_h3 + d) & 0xffffffff;
    _h4 = (_h4 + e) & 0xffffffff;
    _h5 = (_h5 + f) & 0xffffffff;
    _h6 = (_h6 + g) & 0xffffffff;
    _h7 = (_h7 + h) & 0xffffffff;
  }

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xffffffff;
}
