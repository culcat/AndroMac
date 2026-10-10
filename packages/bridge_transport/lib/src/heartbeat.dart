import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';

/// Manages ping/pong heartbeat cadence and detects dead connections.
class HeartbeatManager {
  static const Duration defaultInterval = Duration(seconds: 15);
  static const int defaultMaxMissed = 2; // Disconnect if 2 pongs missed (30s)

  final Duration interval;
  final int maxMissed;
  final void Function(Envelope pingEnvelope) onSendPing;
  final void Function() onTimeout;

  Timer? _timer;
  int _unacknowledgedPings = 0;
  bool _isRunning = false;

  HeartbeatManager({
    this.interval = defaultInterval,
    this.maxMissed = defaultMaxMissed,
    required this.onSendPing,
    required this.onTimeout,
  });

  bool get isRunning => _isRunning;
  int get unacknowledgedPings => _unacknowledgedPings;

  /// Starts the heartbeat periodic timer.
  void start() {
    stop();
    _isRunning = true;
    _unacknowledgedPings = 0;
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  /// Stops the heartbeat timer.
  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _unacknowledgedPings = 0;
  }

  void _tick() {
    if (!_isRunning) return;

    if (_unacknowledgedPings >= maxMissed) {
      stop();
      onTimeout();
      return;
    }

    _unacknowledgedPings++;
    final ping = Envelope.create(
      type: PingPayload.messageType,
      payload:
          PingPayload(timestamp: DateTime.now().millisecondsSinceEpoch).toMap(),
    );
    onSendPing(ping);
  }

  /// Processes an incoming envelope. If it's a pong, acknowledges it.
  /// If it's a ping, returns a corresponding pong envelope to send back.
  Envelope? handleIncomingEnvelope(Envelope envelope) {
    if (envelope.type == PongPayload.messageType) {
      _unacknowledgedPings = 0;
      return null;
    }

    if (envelope.type == PingPayload.messageType) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final pingPayload = PingPayload.fromMap(envelope.payload);
      final pong = Envelope.create(
        type: PongPayload.messageType,
        ref: envelope.id,
        payload: PongPayload(
          timestamp: now,
          receivedTimestamp: pingPayload.timestamp,
        ).toMap(),
      );
      return pong;
    }

    return null;
  }
}
