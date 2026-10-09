import 'dart:async';
import 'dart:io';
import 'transport_channel.dart';

/// Local WebSocket server listening for incoming AndroMac connections (Mac Controller or Phone Provider).
class BridgeServer {
  final InternetAddress address;
  final int port;
  final SecurityContext? securityContext;

  HttpServer? _server;
  final StreamController<TransportChannel> _connectionsController =
      StreamController<TransportChannel>.broadcast();

  BridgeServer({
    InternetAddress? address,
    this.port = 8765,
    this.securityContext,
  }) : address = address ?? InternetAddress.anyIPv4;

  /// Stream of accepted peer connections wrapped in a TransportChannel.
  Stream<TransportChannel> get onConnection => _connectionsController.stream;

  /// Current bound port (useful if port 0 was passed for ephemeral port).
  int get boundPort => _server?.port ?? port;

  /// Starts the HTTP server and begins listening for WebSocket upgrades.
  Future<void> start() async {
    if (_server != null) return;

    if (securityContext != null) {
      _server = await HttpServer.bindSecure(
        address,
        port,
        securityContext!,
        shared: true,
      );
    } else {
      _server = await HttpServer.bind(address, port, shared: true);
    }

    _server!.listen(_handleHttpRequest, onError: (e) {
      // Server error handling
    });
  }

  /// Stops the server and closes all pending connections.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    await _connectionsController.close();
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      try {
        final webSocket = await WebSocketTransformer.upgrade(request);
        final channel = WebSocketTransportChannel(webSocket);
        _connectionsController.add(channel);
      } catch (e) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }
}
