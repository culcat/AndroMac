import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';

void main() {
  group('HeartbeatManager', () {
    test('handles ping and generates matching pong reply', () {
      final pingsSent = <Envelope>[];
      var timeoutCalled = false;

      final manager = HeartbeatManager(
        interval: const Duration(seconds: 15),
        maxMissed: 2,
        onSendPing: (p) => pingsSent.add(p),
        onTimeout: () => timeoutCalled = true,
      );

      final pingEnvelope = Envelope.create(
        type: PingPayload.messageType,
        payload: const PingPayload(timestamp: 1000).toMap(),
      );

      final pongReply = manager.handleIncomingEnvelope(pingEnvelope);
      expect(pongReply, isNotNull);
      expect(pongReply!.type, equals(PongPayload.messageType));
      expect(pongReply.ref, equals(pingEnvelope.id));

      final pongPayload = PongPayload.fromMap(pongReply.payload);
      expect(pongPayload.receivedTimestamp, equals(1000));
      expect(pongPayload.timestamp, isPositive);
      expect(timeoutCalled, isFalse);
    });

    test('receiving pong resets unacknowledged count', () {
      final manager = HeartbeatManager(
        interval: const Duration(seconds: 15),
        maxMissed: 2,
        onSendPing: (_) {},
        onTimeout: () {},
      );

      final pongEnvelope = Envelope.create(
        type: PongPayload.messageType,
        payload: const PongPayload(timestamp: 1015, receivedTimestamp: 1000).toMap(),
      );

      final result = manager.handleIncomingEnvelope(pongEnvelope);
      expect(result, isNull); // Pong does not trigger an auto-reply
      expect(manager.unacknowledgedPings, equals(0));
    });
  });
}
