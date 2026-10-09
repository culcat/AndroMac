import 'package:test/test.dart';
import 'package:otp_feature/otp_feature.dart';

void main() {
  group('OtpExtractor', () {
    test('extracts Google style verification code', () {
      final code = OtpExtractor.extract('G-492019 is your Google verification code.');
      expect(code, equals('492019'));
    });

    test('extracts Telegram verification code', () {
      final code = OtpExtractor.extract('Telegram code: 82914. Do not give this code to anyone.');
      expect(code, equals('82914'));
    });

    test('extracts hyphenated WhatsApp code', () {
      final code = OtpExtractor.extract('Your WhatsApp code is 382-901. Do not share.');
      expect(code, equals('382901'));
    });

    test('extracts Russian Sberbank login code', () {
      final code = OtpExtractor.extract('Код для входа: 9481. Никому не сообщайте.');
      expect(code, equals('9481'));
    });

    test('extracts Russian T-Bank confirmation code', () {
      final code = OtpExtractor.extract('Никому не говорите код подтверждения: 638291.');
      expect(code, equals('638291'));
    });

    test('extracts GitHub 2FA authentication code', () {
      final code = OtpExtractor.extract('Your GitHub authentication code is 782012.');
      expect(code, equals('782012'));
    });

    test('returns null for messages without OTP keywords', () {
      expect(OtpExtractor.extract('Order #10892 has shipped.'), isNull);
      expect(OtpExtractor.extract('Please call me back at +15551234567'), isNull);
      expect(OtpExtractor.extract('Meeting tomorrow at 14:00 in room 402'), isNull);
    });

    test('filters out obvious calendar years', () {
      expect(OtpExtractor.extract('Welcome to the 2026 conference!'), isNull);
    });
  });
}
