import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:clipboard_feature/clipboard_feature.dart';

class MockChannel implements TransportChannel {
  final _incoming = StreamController<Envelope>.broadcast();
  final List<Envelope> sent = <Envelope>[];
  bool _open = true;

  @override
  Stream<Envelope> get incoming => _incoming.stream;

  @override
  bool get isOpen => _open;

  @override
  void send(Envelope envelope) {
    sent.add(envelope);
  }

  @override
  Future<void> close() async {
    _open = false;
    await _incoming.close();
  }
}

void main() {
  group('ClipboardFeature', () {
    test('syncOutbound sends envelope and prevents duplicate transmissions',
        () async {
      final feature = ClipboardFeature(localDeviceId: 'mac-host');
      final channel = MockChannel();
      final context =
          FeatureContext(peerDeviceId: 'phone-peer', channel: channel);

      await feature.start(context);

      final success = feature.syncOutbound('Hello Phone');
      expect(success, isTrue);
      expect(channel.sent.length, equals(1));

      final sentEnvelope = channel.sent.first;
      expect(sentEnvelope.type, equals(ClipboardPayload.messageType));
      final payload = ClipboardPayload.fromMap(sentEnvelope.payload);
      expect(payload.data, equals('Hello Phone'));
      expect(payload.origin, equals('mac-host'));
      expect(payload.seq, equals(1));

      // Attempting to send the identical text again should be suppressed (no-op)
      final duplicateAttempt = feature.syncOutbound('Hello Phone');
      expect(duplicateAttempt, isFalse);
      expect(channel.sent.length, equals(1));
    });

    test('onMessage processes peer updates and suppresses loopback echoes',
        () async {
      final feature = ClipboardFeature(localDeviceId: 'mac-host');
      final channel = MockChannel();
      final context =
          FeatureContext(peerDeviceId: 'phone-peer', channel: channel);

      await feature.start(context);

      final events = <ClipboardItem>[];
      feature.onClipboardChanged.listen(events.add);

      final hash =
          CryptoUtils.toHex(CryptoUtils.sha256String('Phone copied text'));
      final incomingEnvelope = Envelope.create(
        type: ClipboardPayload.messageType,
        payload: ClipboardPayload(
          mime: 'text/plain',
          data: 'Phone copied text',
          hash: hash,
          origin: 'phone-peer',
          seq: 1,
        ).toMap(),
      );

      feature.onMessage(incomingEnvelope);
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(1));
      expect(events.first.content, equals('Phone copied text'));
      expect(feature.history.count, equals(1));

      // Echo message from own device ID should be ignored
      final echoEnvelope = Envelope.create(
        type: ClipboardPayload.messageType,
        payload: ClipboardPayload(
          mime: 'text/plain',
          data: 'Own echoed text',
          hash: 'some-hash',
          origin: 'mac-host', // Matches localDeviceId!
          seq: 2,
        ).toMap(),
      );

      feature.onMessage(echoEnvelope);
      expect(events.length, equals(1)); // No new event
    });
  });
}
