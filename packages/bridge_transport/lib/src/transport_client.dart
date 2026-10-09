import 'dart:async';
import 'dart:io';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'transport_channel.dart';

/// Client establishing outbound WebSocket connection to an AndroMac peer.
class BridgeClient {
  /// Connects to a remote peer via ws:// or wss:// URL.
  ///
  /// If connecting via TLS (wss://) and [pinStore] with [peerDeviceId] is provided,
  /// the server's certificate is validated against the stored SHA-256 fingerprint pin.
  static Future<TransportChannel> connect(
    Uri uri, {
    String? peerDeviceId,
    CertificatePinStore? pinStore,
    SecurityContext? securityContext,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final customClient = HttpClient(context: securityContext);

    if (pinStore != null && peerDeviceId != null) {
      customClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        try {
          return pinStore.verifyCertificate(peerDeviceId, cert.der);
        } catch (_) {
          return false;
        }
      };
    }

    try {
      final webSocket = await WebSocket.connect(
        uri.toString(),
        customClient: customClient,
      ).timeout(timeout);

      return WebSocketTransportChannel(webSocket);
    } catch (e) {
      customClient.close(force: true);
      rethrow;
    }
  }
}
