import 'dart:async';
import 'package:meta/meta.dart';

/// Represents service discovery information for an AndroMac peer advertised over mDNS/DNS-SD.
@immutable
class BridgeServiceInfo {
  /// Standard mDNS service type for AndroMac.
  static const String serviceType = '_bridge._tcp';

  final String deviceId;
  final String name;
  final String host;
  final int port;
  final String fingerprint;
  final int protocolVersion;

  const BridgeServiceInfo({
    required this.deviceId,
    required this.name,
    required this.host,
    required this.port,
    required this.fingerprint,
    this.protocolVersion = 1,
  });

  /// Constructs service info from mDNS TXT record dictionary and socket info.
  factory BridgeServiceInfo.fromTxtRecords({
    required String host,
    required int port,
    required String name,
    required Map<String, String> txt,
  }) {
    return BridgeServiceInfo(
      deviceId: txt['id'] ?? '',
      name: name,
      host: host,
      port: port,
      fingerprint: txt['fp'] ?? '',
      protocolVersion: int.tryParse(txt['v'] ?? '1') ?? 1,
    );
  }

  /// Converts service attributes into mDNS TXT record map.
  Map<String, String> toTxtRecords() {
    return <String, String>{
      'id': deviceId,
      'fp': fingerprint,
      'v': protocolVersion.toString(),
    };
  }

  @override
  String toString() =>
      'BridgeServiceInfo(id: $deviceId, name: $name, host: $host, port: $port, fp: $fingerprint)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeServiceInfo &&
          deviceId == other.deviceId &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => Object.hash(deviceId, host, port);
}

/// Abstract contract for mDNS/DNS-SD service broadcasting and discovery.
abstract interface class DiscoveryService {
  /// Advertises this device's service over local mDNS.
  Future<void> startBroadcasting(BridgeServiceInfo info);

  /// Stops advertising this device.
  Future<void> stopBroadcasting();

  /// Scans local network for available AndroMac peers.
  Stream<BridgeServiceInfo> startDiscovery();

  /// Stops scanning for peers.
  Future<void> stopDiscovery();
}

/// In-memory discovery service for unit tests and synthetic testbeds.
class InMemoryDiscoveryService implements DiscoveryService {
  final _controller = StreamController<BridgeServiceInfo>.broadcast();
  BridgeServiceInfo? _currentBroadcast;

  @override
  Future<void> startBroadcasting(BridgeServiceInfo info) async {
    _currentBroadcast = info;
  }

  @override
  Future<void> stopBroadcasting() async {
    _currentBroadcast = null;
  }

  @override
  Stream<BridgeServiceInfo> startDiscovery() {
    return _controller.stream;
  }

  @override
  Future<void> stopDiscovery() async {
    // No-op for in-memory
  }

  /// Simulates finding an external peer.
  void simulateFoundPeer(BridgeServiceInfo info) {
    _controller.add(info);
  }

  BridgeServiceInfo? get currentBroadcast => _currentBroadcast;

  void dispose() {
    _controller.close();
  }
}
