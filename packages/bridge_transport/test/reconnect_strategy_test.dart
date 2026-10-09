import 'dart:math';
import 'package:test/test.dart';
import 'package:bridge_transport/bridge_transport.dart';

void main() {
  group('ReconnectStrategy', () {
    test('calculates exponential backoff delays', () {
      final strategy = ReconnectStrategy(
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 16),
        multiplier: 2.0,
        jitterFactor: 0.0, // Zero jitter for deterministic check
        random: Random(42),
      );

      expect(strategy.attempts, equals(0));

      final delay1 = strategy.nextDelay();
      expect(delay1.inSeconds, equals(1));
      expect(strategy.attempts, equals(1));

      final delay2 = strategy.nextDelay();
      expect(delay2.inSeconds, equals(2));

      final delay3 = strategy.nextDelay();
      expect(delay3.inSeconds, equals(4));

      final delay4 = strategy.nextDelay();
      expect(delay4.inSeconds, equals(8));

      final delay5 = strategy.nextDelay();
      expect(delay5.inSeconds, equals(16));

      // Clamped to maxDelay
      final delay6 = strategy.nextDelay();
      expect(delay6.inSeconds, equals(16));
    });

    test('reset clears attempts count', () {
      final strategy = ReconnectStrategy();
      strategy.nextDelay();
      strategy.nextDelay();
      expect(strategy.attempts, equals(2));

      strategy.reset();
      expect(strategy.attempts, equals(0));
    });
  });
}
