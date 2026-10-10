import 'dart:typed_data';
import 'crypto_utils.dart';

/// Generates Short Authentication String (SAS) for visual verification during pairing.
class SasGenerator {
  /// Curated list of distinct, recognizable emojis for visual SAS comparison.
  static const List<String> emojiPalette = [
    '🐶',
    '🐱',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🦁',
    '🐯',
    '🍎',
    '🍓',
    '🍒',
    '🍉',
    '🍕',
    '🚀',
    '⭐',
    '🎈',
    '🎸',
    '⚡',
    '🔥',
    '🌊',
    '💎',
    '🔑',
    '🍀',
    '🔔',
    '☕',
    '👑',
    '⚓',
    '🚲',
    '✈️',
    '⛵',
    '🏀',
    '⚽'
  ];

  /// Computes SAS from client and server certificate fingerprints and the temporary pairing code.
  ///
  /// Order of fingerprints does not matter: they are sorted lexicographically to ensure
  /// identical output on both initiator and responder.
  static SasResult compute({
    required String fingerprintA,
    required String fingerprintB,
    required String pairingCode,
  }) {
    final cleanA = fingerprintA.replaceAll(':', '').toLowerCase();
    final cleanB = fingerprintB.replaceAll(':', '').toLowerCase();

    // Sort lexicographically
    final first = cleanA.compareTo(cleanB) <= 0 ? cleanA : cleanB;
    final second = cleanA.compareTo(cleanB) <= 0 ? cleanB : cleanA;

    final combined = '$first:$second:$pairingCode';
    final hash = CryptoUtils.sha256String(combined);

    final emojiList = <String>[];
    for (var i = 0; i < 4; i++) {
      final idx = hash[4 + i] % emojiPalette.length;
      emojiList.add(emojiPalette[idx]);
    }

    return SasResult(
      numericCode: _deriveNumeric(hash),
      emojiCode: emojiList.join(),
      emojiList: emojiList,
    );
  }

  /// Derives a 6-digit formatted string: "XXX-XXX"
  static String _deriveNumeric(Uint8List hash) {
    // Use first 4 bytes to form a 32-bit unsigned integer
    final value = (hash[0] << 24) | (hash[1] << 16) | (hash[2] << 8) | hash[3];
    final num = (value & 0x7FFFFFFF) % 1000000;
    final str = num.toString().padLeft(6, '0');
    return '${str.substring(0, 3)}-${str.substring(3)}';
  }
}

/// Verification string result containing numeric and visual emoji codes.
class SasResult {
  /// Numeric code formatted as "123-456".
  final String numericCode;

  /// Visual code formatted as 4 emojis.
  final String emojiCode;

  /// List of individual emojis.
  final List<String> emojiList;

  const SasResult({
    required this.numericCode,
    required this.emojiCode,
    this.emojiList = const <String>[],
  });

  @override
  String toString() => 'SasResult(numeric: $numericCode, emoji: $emojiCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SasResult &&
          numericCode == other.numericCode &&
          emojiCode == other.emojiCode;

  @override
  int get hashCode => Object.hash(numericCode, emojiCode);
}
