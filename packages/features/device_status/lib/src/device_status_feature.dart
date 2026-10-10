import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_core/bridge_core.dart';
import 'device_status_state.dart';

/// Feature plugin coordinating battery/network telemetry and Find My Phone alert ringing.
class DeviceStatusFeature implements BridgeFeature {
  static const String ringMessageType = 'find.ring';

  @override
  final String id = 'device_status';

  @override
  final Set<String> incomingTypes = const <String>{
    DeviceStatusPayload.messageType,
    ringMessageType,
  };

  final StreamController<DeviceStatusState> _statusController =
      StreamController<DeviceStatusState>.broadcast();
  final StreamController<void> _ringTriggerController =
      StreamController<void>.broadcast();

  FeatureContext? _context;
  DeviceStatusState _currentStatus = DeviceStatusState.unknown();

  /// Provider-side callback invoked on Android when Mac triggers "Find My Phone".
  Function? onRingRequested;

  DeviceStatusFeature({this.onRingRequested});

  /// The most recent cached status of the remote device.
  DeviceStatusState get currentStatus => _currentStatus;

  /// Stream of status telemetry updates.
  Stream<DeviceStatusState> get onStatusChanged => _statusController.stream;

  /// Stream signaling that this phone should play an emergency loud ring sound.
  Stream<void> get onRingTriggered => _ringTriggerController.stream;

  @override
  Future<void> start(FeatureContext ctx) async {
    _context = ctx;
  }

  @override
  Future<void> stop() async {
    _context = null;
  }

  @override
  void onMessage(Envelope message) {
    if (message.type == DeviceStatusPayload.messageType) {
      final payload = DeviceStatusPayload.fromMap(message.payload);
      final newState = DeviceStatusState(
        batteryLevel: payload.batteryLevel,
        isCharging: payload.isCharging,
        networkType: payload.networkType,
        wifiSignalStrength: payload.wifiSignalStrength,
        isDndActive: payload.isDndActive,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(message.ts),
      );

      _currentStatus = newState;
      _statusController.add(newState);
    } else if (message.type == ringMessageType) {
      final reason = message.payload['reason'] as String?;
      _ringTriggerController.add(null);
      if (onRingRequested != null) {
        if (onRingRequested is void Function(String?)) {
          (onRingRequested as void Function(String?))(reason);
        } else if (onRingRequested is void Function()) {
          (onRingRequested as void Function())();
        } else {
          try {
            (onRingRequested as dynamic)(reason);
          } catch (_) {
            (onRingRequested as dynamic)();
          }
        }
      }
    }
  }

  /// Sends a command from Mac requesting the phone to play a loud alert sound.
  bool ringRemotePhone() {
    if (_context == null || !_context!.isConnected) return false;

    final envelope = Envelope.create(
      type: ringMessageType,
      payload: const <String, dynamic>{},
    );

    _context!.send(envelope);
    return true;
  }

  /// Sends local battery and connectivity status (called periodically or on change by Android).
  bool broadcastLocalStatus({
    required int batteryLevel,
    required bool isCharging,
    required String networkType,
    int? wifiSignalStrength,
    bool isDndActive = false,
  }) {
    if (_context == null || !_context!.isConnected) return false;

    final payload = DeviceStatusPayload(
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      networkType: networkType,
      wifiSignalStrength: wifiSignalStrength,
      isDndActive: isDndActive,
    );

    final envelope = Envelope.create(
      type: DeviceStatusPayload.messageType,
      payload: payload.toMap(),
    );

    _context!.send(envelope);
    return true;
  }

  void dispose() {
    _statusController.close();
    _ringTriggerController.close();
  }
}
