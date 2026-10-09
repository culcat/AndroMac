import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';

void main() {
  group('BridgeServer and BridgeClient loopback communication', () {
    test('client connects to server and exchanges envelopes', () async {
      final server = BridgeServer(
        address: InternetAddress.loopbackIPv4,
        port: 0, // Ephemeral port
      );
      await server.start();
      final port = server.boundPort;

      final serverReceivedCompleter = Completer<Envelope>();
      TransportChannel? serverSideChannel;

      final serverSub = server.onConnection.listen((channel) {
        serverSideChannel = channel;
        channel.incoming.listen((envelope) {
          if (!serverReceivedCompleter.isCompleted) {
            serverReceivedCompleter.complete(envelope);
          }
        });
      });

      final clientUri = Uri.parse('ws://127.0.0.1:$port');
      final clientChannel = await BridgeClient.connect(clientUri);

      expect(clientChannel.isOpen, isTrue);

      // Send message from client to server
      final testEnvelope = Envelope.create(
        type: ClipboardPayload.messageType,
        payload: const ClipboardPayload(
          mime: 'text/plain',
          data: 'Loopback test data',
          hash: 'sha256-test',
          origin: 'test-client',
          seq: 1,
        ).toMap(),
      );

      clientChannel.send(testEnvelope);

      final receivedByServer = await serverReceivedCompleter.future.timeout(
        const Duration(seconds: 5),
      );

      expect(receivedByServer.type, equals(ClipboardPayload.messageType));
      expect(receivedByServer.payload['data'], equals('Loopback test data'));

      // Clean up
      await clientChannel.close();
      await serverSideChannel?.close();
      await serverSub.cancel();
      await server.stop();
    });
  });
}
