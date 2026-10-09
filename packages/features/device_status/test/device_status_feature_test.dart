import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:device_status_feature/device_status_feature.dart';

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
  group('DeviceStatusFeature', () {
    test('broadcastLocalStatus sends device.status envelope with battery/network info', () async {
      final feature = DeviceStatusFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'mac-1', channel: channel);
      await feature.start(context);

      final success = feature.broadcastLocalStatus(
        batteryLevel: 88,
        isCharging: true,
        networkType: 'wifi',
        wifiSignalStrength: 3,
        isDndActive: false,
      );

      expect(success, isTrue);
      expect(channel.sent.length, equals(1));

      final envelope = channel.sent.first;
      expect(envelope.type, equals(DeviceStatusPayload.messageType));
      final payload = DeviceStatusPayload.fromMap(envelope.payload);
      expect(payload.batteryLevel, equals(88));
      expect(payload.isCharging, isTrue);
      expect(payload.networkType, equals('wifi'));
      expect(payload.wifiSignalStrength, equals(3));
    });

    test('onMessage updates currentStatus and emits to stream', () async {
      final feature = DeviceStatusFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final statusEvents = <DeviceStatusState>[];
      feature.onStatusChanged.listen(statusEvents.add);

      final incomingEnvelope = Envelope.create(
        type: DeviceStatusPayload.messageType,
        payload: const DeviceStatusPayload(
          batteryLevel: 65,
          isCharging: false,
          networkType: 'cellular',
          isDndActive: true,
        ).toMap(),
      );

      feature.onMessage(incomingEnvelope);

      expect(statusEvents.length, equals(1));
      final state = feature.currentStatus;
      expect(state.batteryLevel, equals(65));
      expect(state.isCharging, isFalse);
      expect(state.networkType, equals('cellular'));
      expect(state.isDndActive, isTrue);
    });

    test('ringRemotePhone sends find.ring command', () async {
      final feature = DeviceStatusFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final success = feature.ringRemotePhone();
      expect(success, isTrue);
      expect(channel.sent.length, equals(1));
      expect(channel.sent.first.type, equals(DeviceStatusFeature.ringMessageType));
    });

    test('receiving find.ring triggers onRingTriggered stream and callback on Android', () async {
      var callbackInvoked = false;
      final feature = DeviceStatusFeature(
        onRingRequested: () => callbackInvoked = true,
      );

      final ringEvents = <void>[];
      feature.onRingTriggered.listen(ringEvents.add);

      final ringEnvelope = Envelope.create(
        type: DeviceStatusFeature.ringMessageType,
        payload: const <String, dynamic>{},
      );

      feature.onMessage(ringEnvelope);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(callbackInvoked, isTrue);
      expect(ringEvents.length, equals(1));
    });
  });
}
