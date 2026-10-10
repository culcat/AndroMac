import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:fake_phone/fake_phone.dart';

/// Bidirectional in-memory paired transport channels simulating a local network link.
class PipedTransportChannelPair {
  final _aToB = StreamController<Envelope>.broadcast();
  final _bToA = StreamController<Envelope>.broadcast();

  late final TransportChannel channelA;
  late final TransportChannel channelB;

  PipedTransportChannelPair() {
    channelA = _PipedChannel(_bToA.stream, _aToB);
    channelB = _PipedChannel(_aToB.stream, _bToA);
  }

  void close() {
    _aToB.close();
    _bToA.close();
  }
}

class _PipedChannel implements TransportChannel {
  final Stream<Envelope> _incoming;
  final StreamController<Envelope> _outgoing;
  bool _open = true;

  _PipedChannel(this._incoming, this._outgoing);

  @override
  Stream<Envelope> get incoming => _incoming;

  @override
  bool get isOpen => _open;

  @override
  void send(Envelope envelope) {
    if (_open && !_outgoing.isClosed) {
      _outgoing.add(envelope);
    }
  }

  @override
  Future<void> close() async {
    _open = false;
  }
}

void main() {
  group('Chaos Network & Resilience Testing', () {
    test(
        'reconnection backoff strategy calculates monotonic delays with bounded jitter',
        () {
      final strategy = ReconnectStrategy(
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 30),
        multiplier: 1.5,
        jitterFactor: 0.2,
      );

      // Verify attempts scale exponentially up to maxDelay
      final d0 = strategy.nextDelay();
      final d1 = strategy.nextDelay();
      final d2 = strategy.nextDelay();

      expect(d0.inMilliseconds, greaterThanOrEqualTo(800));
      expect(d0.inMilliseconds, lessThanOrEqualTo(1200));

      expect(d1.inMilliseconds, greaterThanOrEqualTo(1200));
      expect(d1.inMilliseconds, lessThanOrEqualTo(1800));

      expect(d2.inMilliseconds, greaterThanOrEqualTo(1800));
      expect(d2.inMilliseconds, lessThanOrEqualTo(2700));

      expect(strategy.attempts, equals(3));
    });

    test('heartbeat manager auto-responds to ping with pong', () async {
      final pair = PipedTransportChannelPair();

      final manager = HeartbeatManager(
        interval: const Duration(milliseconds: 100),
        onSendPing: (ping) => pair.channelA.send(ping),
        onTimeout: () {},
      );

      pair.channelA.incoming.listen((envelope) {
        final reply = manager.handleIncomingEnvelope(envelope);
        if (reply != null) {
          pair.channelA.send(reply);
        }
      });
      manager.start();

      Envelope? receivedPong;
      pair.channelB.incoming.listen((envelope) {
        if (envelope.type == PongPayload.messageType) {
          receivedPong = envelope;
        }
      });

      // Send ping from side B to side A
      final pingEnv = Envelope.create(
        type: PingPayload.messageType,
        payload: const PingPayload(timestamp: 1000).toMap(),
      );
      pair.channelB.send(pingEnv);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(receivedPong, isNotNull);
      expect(receivedPong!.type, equals(PongPayload.messageType));
      expect(receivedPong!.payload['receivedTimestamp'], equals(1000));

      manager.stop();
      pair.close();
    });

    test(
        'synthetic peer interaction survives simulated network drop and reconnect',
        () async {
      final device = FakePhoneDevice(name: 'Chaos Pixel 8');

      // 1. Establish initial connection
      var pair = PipedTransportChannelPair();
      final macIncoming = <Envelope>[];
      pair.channelB.incoming.listen(macIncoming.add);
      await device.attach(pair.channelA);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Phone sends initial hello
      expect(
          macIncoming.any((e) => e.type == HelloPayload.messageType), isTrue);

      // Simulate Mac accepting hello
      pair.channelB.send(Envelope.create(
        type: HelloAckPayload.messageType,
        payload: const HelloAckPayload(
          accepted: true,
          deviceId: 'mac-controller-1',
          agreedCapabilities: [
            'clipboard',
            'notifications',
            'sms',
            'device_status'
          ],
        ).toMap(),
      ));

      // Send telemetry
      device.sendBatteryStatus(batteryLevel: 77, isCharging: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(macIncoming.any((e) => e.type == DeviceStatusPayload.messageType),
          isTrue);

      // 2. Simulate abrupt network disconnection (drop channel)
      await pair.channelA.close();
      await pair.channelB.close();
      pair.close();

      // 3. Re-establish connection on new network link
      final newPair = PipedTransportChannelPair();
      final newMacIncoming = <Envelope>[];
      newPair.channelB.incoming.listen(newMacIncoming.add);
      await device.attach(newPair.channelA);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Device sends fresh hello on new connection
      expect(newMacIncoming.any((e) => e.type == HelloPayload.messageType),
          isTrue);

      // Send SMS event through re-established link
      device.sendSms(address: 'TestSender', body: 'Reconnection verified');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final smsReceived = newMacIncoming
          .firstWhere((e) => e.type == SmsReceivedPayload.messageType);
      expect(smsReceived.payload['address'], equals('TestSender'));
      expect(smsReceived.payload['body'], equals('Reconnection verified'));

      newPair.close();
    });
  });
}
