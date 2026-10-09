import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';

/// Context provided to a [BridgeFeature] upon activation.
class FeatureContext {
  /// Unique device identifier of the currently connected remote peer.
  final String peerDeviceId;

  /// Underlying transport channel to send envelopes.
  final TransportChannel _channel;

  FeatureContext({
    required this.peerDeviceId,
    required TransportChannel channel,
  }) : _channel = channel;

  /// Sends a message envelope to the connected peer.
  void send(Envelope message) {
    _channel.send(message);
  }

  /// Direct access to incoming envelope stream from peer.
  Stream<Envelope> get incoming => _channel.incoming;

  /// Whether the connection is active.
  bool get isConnected => _channel.isOpen;
}
