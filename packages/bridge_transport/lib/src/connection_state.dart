/// Represents the high-level connection lifecycle between paired devices.
enum ConnectionState {
  /// No active connection; idle or closed.
  disconnected,

  /// Actively seeking peer via mDNS or direct IP.
  discovering,

  /// Socket connection in progress (TCP / TLS handshake).
  connecting,

  /// Exchanging 'hello' / 'hello.ack' protocol handshake and capability negotiation.
  handshaking,

  /// Fully authenticated, pinned, and operational.
  connected,

  /// Connection lost; attempting backoff reconnection.
  reconnecting,

  /// Terminal or fatal error state.
  error,
}

/// Detailed status snapshot of the transport connection.
class ConnectionStatus {
  final ConnectionState state;
  final String? peerDeviceId;
  final String? peerAddress;
  final int? peerPort;
  final String? errorMessage;
  final DateTime updatedAt;

  const ConnectionStatus({
    required this.state,
    this.peerDeviceId,
    this.peerAddress,
    this.peerPort,
    this.errorMessage,
    required this.updatedAt,
  });

  factory ConnectionStatus.initial() => ConnectionStatus(
        state: ConnectionState.disconnected,
        updatedAt: DateTime.now(),
      );

  ConnectionStatus copyWith({
    ConnectionState? state,
    String? peerDeviceId,
    String? peerAddress,
    int? peerPort,
    String? errorMessage,
    DateTime? updatedAt,
  }) {
    return ConnectionStatus(
      state: state ?? this.state,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      peerAddress: peerAddress ?? this.peerAddress,
      peerPort: peerPort ?? this.peerPort,
      errorMessage: errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() =>
      'ConnectionStatus(state: $state, peer: $peerDeviceId@$peerAddress:$peerPort, error: $errorMessage)';
}
