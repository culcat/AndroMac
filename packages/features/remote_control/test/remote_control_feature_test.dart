import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:remote_control_feature/remote_control_feature.dart';

class MockTransportChannel implements TransportChannel {
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
  group('RemoteControlFeature', () {
    test('sendInput dispatches normalized remote.control.input envelope', () async {
      final feature = RemoteControlFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final event = const RemoteInputEvent(
        type: RemoteInputType.down,
        xRatio: 0.45,
        yRatio: 0.75,
        button: 0,
      );

      final success = feature.sendInput(event);
      expect(success, isTrue);
      expect(channel.sent.length, equals(1));

      final envelope = channel.sent.first;
      expect(envelope.type, equals(RemoteControlFeature.typeInput));
      final payload = RemoteInputEvent.fromMap(envelope.payload);
      expect(payload.type, equals(RemoteInputType.down));
      expect(payload.xRatio, equals(0.45));
      expect(payload.yRatio, equals(0.75));
    });

    test('sendNavButton dispatches remote.control.nav envelope', () async {
      final feature = RemoteControlFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final success = feature.sendNavButton(AndroidNavButton.home);
      expect(success, isTrue);
      expect(channel.sent.length, equals(1));

      final envelope = channel.sent.first;
      expect(envelope.type, equals(RemoteControlFeature.typeNav));
      expect(envelope.payload['button'], equals('home'));
    });

    test('requestSetup dispatches remote.setup.request with streaming profile', () async {
      final feature = RemoteControlFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      const profile = RemoteControlProfile(
        maxFps: 60,
        bitRateMbps: 12,
        maxResolution: 1920,
        audioEnabled: true,
      );

      final success = feature.requestSetup(profile: profile);
      expect(success, isTrue);
      expect(channel.sent.length, equals(1));

      final envelope = channel.sent.first;
      expect(envelope.type, equals(RemoteControlFeature.typeSetupRequest));
      final parsed = RemoteControlProfile.fromMap(envelope.payload);
      expect(parsed.maxFps, equals(60));
      expect(parsed.bitRateMbps, equals(12));
    });

    test('receiving input triggers callbacks and emits on stream on Android provider', () async {
      RemoteInputEvent? receivedInput;
      AndroidNavButton? receivedNav;

      final feature = RemoteControlFeature(
        onInputReceived: (e) => receivedInput = e,
        onNavButtonReceived: (b) => receivedNav = b,
      );

      final inputEnvelope = Envelope.create(
        type: RemoteControlFeature.typeInput,
        payload: const RemoteInputEvent(
          type: RemoteInputType.text,
          text: 'Typing on phone keyboard',
        ).toMap(),
      );

      final navEnvelope = Envelope.create(
        type: RemoteControlFeature.typeNav,
        payload: const {'button': 'recents'},
      );

      feature.onMessage(inputEnvelope);
      feature.onMessage(navEnvelope);

      expect(receivedInput, isNotNull);
      expect(receivedInput!.text, equals('Typing on phone keyboard'));
      expect(receivedNav, equals(AndroidNavButton.recents));
    });
  });
}
