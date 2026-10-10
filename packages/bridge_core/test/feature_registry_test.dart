import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';

class FakeFeature implements BridgeFeature {
  @override
  final String id;
  @override
  final Set<String> incomingTypes;

  bool isStarted = false;
  final List<Envelope> receivedMessages = <Envelope>[];

  FakeFeature({required this.id, required this.incomingTypes});

  @override
  Future<void> start(FeatureContext ctx) async {
    isStarted = true;
  }

  @override
  Future<void> stop() async {
    isStarted = false;
  }

  @override
  void onMessage(Envelope message) {
    receivedMessages.add(message);
  }
}

class FakeTransportChannel implements TransportChannel {
  final _controller = StreamController<Envelope>.broadcast();
  final List<Envelope> sent = <Envelope>[];
  bool _open = true;

  @override
  Stream<Envelope> get incoming => _controller.stream;

  @override
  bool get isOpen => _open;

  @override
  void send(Envelope envelope) {
    sent.add(envelope);
  }

  @override
  Future<void> close() async {
    _open = false;
    await _controller.close();
  }
}

void main() {
  group('FeatureRegistry', () {
    test('registers features and advertises capabilities', () {
      final registry = FeatureRegistry();
      final clip =
          FakeFeature(id: 'clipboard', incomingTypes: {'clipboard.update'});
      final notif =
          FakeFeature(id: 'notifications', incomingTypes: {'notif.posted'});

      registry.register(clip);
      registry.register(notif);

      expect(registry.supportedCapabilities,
          containsAll(['clipboard', 'notifications']));
      expect(() => registry.register(clip), throwsArgumentError);
    });

    test('activates only agreed capabilities', () async {
      final registry = FeatureRegistry();
      final clip =
          FakeFeature(id: 'clipboard', incomingTypes: {'clipboard.update'});
      final sms = FakeFeature(id: 'sms', incomingTypes: {'sms.received'});

      registry.register(clip);
      registry.register(sms);

      final channel = FakeTransportChannel();
      final context = FeatureContext(peerDeviceId: 'mac-1', channel: channel);

      // Remote peer only supports 'clipboard'
      await registry.startAgreedFeatures(context, ['clipboard']);

      expect(registry.activeFeatureIds, equals({'clipboard'}));
      expect(clip.isStarted, isTrue);
      expect(sms.isStarted, isFalse);

      await registry.stopAll();
      expect(registry.activeFeatureIds, isEmpty);
      expect(clip.isStarted, isFalse);
    });

    test('routes messages only to subscribed active features', () async {
      final registry = FeatureRegistry();
      final clip =
          FakeFeature(id: 'clipboard', incomingTypes: {'clipboard.update'});
      final sms = FakeFeature(id: 'sms', incomingTypes: {'sms.received'});

      registry.register(clip);
      registry.register(sms);

      final channel = FakeTransportChannel();
      final context = FeatureContext(peerDeviceId: 'mac-1', channel: channel);

      await registry.startAgreedFeatures(context, ['clipboard', 'sms']);

      final clipMsg = Envelope.create(type: 'clipboard.update');
      final smsMsg = Envelope.create(type: 'sms.received');

      registry.dispatch(clipMsg);
      registry.dispatch(smsMsg);

      expect(clip.receivedMessages.length, equals(1));
      expect(clip.receivedMessages.first.type, equals('clipboard.update'));

      expect(sms.receivedMessages.length, equals(1));
      expect(sms.receivedMessages.first.type, equals('sms.received'));
    });
  });
}
