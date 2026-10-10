import 'dart:async';
import 'dart:io';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'heartbeat.dart';

/// Bidirectional message channel transporting Envelopes over a WebSocket connection.
abstract interface class TransportChannel {
  /// Stream of incoming protocol envelopes from the remote peer.
  Stream<Envelope> get incoming;

  /// Sends a protocol envelope to the remote peer.
  void send(Envelope envelope);

  /// Closes the underlying socket connection.
  Future<void> close();

  /// Whether the underlying channel is currently open and active.
  bool get isOpen;
}

/// WebSocket-backed implementation of [TransportChannel] with integrated heartbeat handling.
class WebSocketTransportChannel implements TransportChannel {
  final WebSocket _socket;
  final StreamController<Envelope> _incomingController =
      StreamController<Envelope>.broadcast();
  late final HeartbeatManager _heartbeat;
  bool _isOpen = true;

  WebSocketTransportChannel(this._socket, {HeartbeatManager? heartbeat}) {
    _heartbeat = heartbeat ??
        HeartbeatManager(
          onSendPing: send,
          onTimeout: _handleHeartbeatTimeout,
        );

    _socket.listen(
      _handleRawMessage,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: true,
    );

    _heartbeat.start();
  }

  @override
  Stream<Envelope> get incoming => _incomingController.stream;

  @override
  bool get isOpen => _isOpen;

  @override
  void send(Envelope envelope) {
    if (!_isOpen) {
      throw StateError(
          'Cannot send envelope on closed WebSocketTransportChannel');
    }
    _socket.add(envelope.encode());
  }

  @override
  Future<void> close() async {
    if (!_isOpen) return;
    _isOpen = false;
    _heartbeat.stop();
    await _socket.close();
    await _incomingController.close();
  }

  void _handleRawMessage(dynamic data) {
    if (data is! String) return;

    try {
      final envelope = Envelope.decode(data);
      // Let heartbeat inspect envelope (e.g. reply to ping with pong, or record pong)
      final autoReply = _heartbeat.handleIncomingEnvelope(envelope);
      if (autoReply != null) {
        send(autoReply);
      }

      // Forward non-heartbeat messages (or all messages) to application consumers
      if (envelope.type != PingPayload.messageType &&
          envelope.type != PongPayload.messageType) {
        _incomingController.add(envelope);
      }
    } catch (e) {
      // Protocol decode error — ignore corrupt frames or dispatch error envelope
    }
  }

  void _handleHeartbeatTimeout() {
    close();
  }

  void _handleError(Object error) {
    close();
  }

  void _handleDone() {
    _isOpen = false;
    _heartbeat.stop();
    if (!_incomingController.isClosed) {
      _incomingController.close();
    }
  }
}
