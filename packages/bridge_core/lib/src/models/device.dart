import 'package:meta/meta.dart';

/// Platform operating system.
enum DevicePlatform {
  android,
  macos,
  unknown;

  static DevicePlatform fromString(String str) {
    switch (str.toLowerCase()) {
      case 'android':
        return DevicePlatform.android;
      case 'macos':
        return DevicePlatform.macos;
      default:
        return DevicePlatform.unknown;
    }
  }
}

/// Representation of a local or remote device in AndroMac.
@immutable
class Device {
  final String id;
  final String name;
  final DevicePlatform platform;
  final String appVersion;
  final int protocolVersion;

  const Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.appVersion,
    this.protocolVersion = 1,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'platform': platform.name,
      'appVersion': appVersion,
      'protocolVersion': protocolVersion,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      platform: DevicePlatform.fromString(map['platform'] as String? ?? ''),
      appVersion: map['appVersion'] as String? ?? '',
      protocolVersion: map['protocolVersion'] as int? ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Device && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Device(id: $id, name: $name, platform: ${platform.name})';
}

/// Representation of a paired peer device with security credentials and feature flags.
@immutable
class PeerDevice {
  final Device device;
  final String certificateFingerprint;
  final DateTime pairedAt;
  final DateTime? lastSeenAt;
  final Set<String> enabledFeatures;
  final bool isOnline;

  const PeerDevice({
    required this.device,
    required this.certificateFingerprint,
    required this.pairedAt,
    this.lastSeenAt,
    this.enabledFeatures = const <String>{},
    this.isOnline = false,
  });

  PeerDevice copyWith({
    Device? device,
    String? certificateFingerprint,
    DateTime? pairedAt,
    DateTime? lastSeenAt,
    Set<String>? enabledFeatures,
    bool? isOnline,
  }) {
    return PeerDevice(
      device: device ?? this.device,
      certificateFingerprint:
          certificateFingerprint ?? this.certificateFingerprint,
      pairedAt: pairedAt ?? this.pairedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  String toString() =>
      'PeerDevice(id: ${device.id}, name: ${device.name}, online: $isOnline)';
}
