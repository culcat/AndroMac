import 'dart:math';

/// Calculates exponential backoff intervals with random jitter to prevent reconnection storms.
class ReconnectStrategy {
  final Duration initialDelay;
  final Duration maxDelay;
  final double multiplier;
  final double jitterFactor;
  final Random _random;

  int _attempts = 0;

  ReconnectStrategy({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.multiplier = 1.5,
    this.jitterFactor = 0.2,
    Random? random,
  }) : _random = random ?? Random();

  /// Current number of failed consecutive attempts.
  int get attempts => _attempts;

  /// Computes the next backoff duration and increments attempt counter.
  Duration nextDelay() {
    final currentMultiplier = pow(multiplier, _attempts).toDouble();
    final calculatedMs =
        (initialDelay.inMilliseconds * currentMultiplier).clamp(
      initialDelay.inMilliseconds.toDouble(),
      maxDelay.inMilliseconds.toDouble(),
    );

    // Add jitter: [-jitterFactor, +jitterFactor]
    final jitterRange = calculatedMs * jitterFactor;
    final jitterOffset = (_random.nextDouble() * 2 - 1) * jitterRange;
    final finalMs = (calculatedMs + jitterOffset).clamp(
      initialDelay.inMilliseconds.toDouble(),
      maxDelay.inMilliseconds.toDouble(),
    );

    _attempts++;
    return Duration(milliseconds: finalMs.round());
  }

  /// Resets attempt count upon successful connection.
  void reset() {
    _attempts = 0;
  }
}
