/// Intelligent heuristic parser extracting 4-8 digit one-time verification codes (ru/en).
class OtpExtractor {
  static const List<String> _triggerKeywords = [
    // English
    'code',
    'verification',
    'verify',
    'password',
    'passcode',
    'security',
    'login',
    'confirm',
    'pin',
    'otp',
    '2fa',
    'auth',
    // Russian
    'код',
    'пароль',
    'подтверждения',
    'входа',
    'авторизации',
    'проверочный',
    'смс-код',
  ];

  static final List<RegExp> _codePatterns = [
    // Pattern 1: Explicit keyword followed by 4-8 digits, with optional colon or hyphen (e.g. "code: 123456", "код 7890")
    RegExp(
      r'(?:code|код|password|пароль|pin|пин|is|это|:)\s*[:=-]?\s*([0-9]{4,8})\b',
      caseSensitive: false,
    ),
    // Pattern 2: Hyphenated codes (e.g. "123-456")
    RegExp(
      r'\b([0-9]{3}-[0-9]{3})\b',
    ),
    // Pattern 3: Prefixed Google/service format (e.g. "G-123456")
    RegExp(
      r'\b(?:G|V|FB|VK|TG)-([0-9]{4,6})\b',
      caseSensitive: false,
    ),
  ];

  static final RegExp _fallbackDigits = RegExp(r'\b([0-9]{4,8})\b');

  /// Attempts to extract a one-time verification code from [text].
  ///
  /// Returns the extracted string code, or null if no verification code was detected.
  static String? extract(String text) {
    if (text.trim().isEmpty) return null;

    final lower = text.toLowerCase();

    // Check if the message contains at least one verification-related keyword
    final containsKeyword = _triggerKeywords.any((k) => lower.contains(k));
    if (!containsKeyword) return null;

    // Try primary high-confidence patterns
    for (final pattern in _codePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final captured = match.group(1);
        if (captured != null && _isValidCandidate(captured)) {
          return captured.replaceAll('-', '');
        }
      }
    }

    // Secondary fallback: find isolated 4-8 digit numbers in the text that are not dates or amounts
    for (final match in _fallbackDigits.allMatches(text)) {
      final candidate = match.group(1);
      if (candidate != null && _isValidCandidate(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  static bool _isValidCandidate(String candidate) {
    final clean = candidate.replaceAll('-', '');

    // Must be between 4 and 8 digits
    if (clean.length < 4 || clean.length > 8) return false;

    // Reject obvious current calendar years
    if (clean == '2024' || clean == '2025' || clean == '2026' || clean == '2027') {
      return false;
    }

    // Reject repetitive dummy numbers like "0000" or "1111"
    if (RegExp(r'^([0-9])\1+$').hasMatch(clean)) {
      return false;
    }

    return true;
  }
}
