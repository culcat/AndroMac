import 'package:meta/meta.dart';
import 'package:bridge_crypto/bridge_crypto.dart';

/// Configuration and display helper for visual SAS confirmation during pairing.
@immutable
class SasDisplayCard {
  final String formattedNumeric;
  final String emojiCode;
  final String instruction;

  const SasDisplayCard({
    required this.formattedNumeric,
    required this.emojiCode,
    this.instruction =
        'Verify that both devices show identical code and emojis',
  });

  factory SasDisplayCard.fromSasResult(
    SasResult sas, {
    String? instruction,
  }) {
    return SasDisplayCard(
      formattedNumeric: sas.numericCode,
      emojiCode: sas.emojiCode,
      instruction: instruction ??
          'Verify that both devices show identical code and emojis',
    );
  }

  @override
  String toString() =>
      'SasDisplayCard(numeric: $formattedNumeric, emojis: $emojiCode)';
}
