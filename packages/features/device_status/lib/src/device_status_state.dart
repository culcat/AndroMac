import 'package:meta/meta.dart';

/// Current battery, network, and system state of the connected phone.
@immutable
class DeviceStatusState {
  final int batteryLevel; // 0 - 100
  final bool isCharging;
  final String networkType; // 'wifi' | 'cellular' | 'ethernet' | 'none'
  final int? wifiSignalStrength; // 0 - 4
  final bool isDndActive; // Do Not Disturb status
  final DateTime lastUpdated;

  const DeviceStatusState({
    required this.batteryLevel,
    required this.isCharging,
    required this.networkType,
    this.wifiSignalStrength,
    this.isDndActive = false,
    required this.lastUpdated,
  });

  factory DeviceStatusState.unknown() => DeviceStatusState(
        batteryLevel: 0,
        isCharging: false,
        networkType: 'none',
        wifiSignalStrength: null,
        isDndActive: false,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
      );

  DeviceStatusState copyWith({
    int? batteryLevel,
    bool? isCharging,
    String? networkType,
    int? wifiSignalStrength,
    bool? isDndActive,
    DateTime? lastUpdated,
  }) {
    return DeviceStatusState(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      networkType: networkType ?? this.networkType,
      wifiSignalStrength: wifiSignalStrength ?? this.wifiSignalStrength,
      isDndActive: isDndActive ?? this.isDndActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceStatusState &&
          batteryLevel == other.batteryLevel &&
          isCharging == other.isCharging &&
          networkType == other.networkType &&
          wifiSignalStrength == other.wifiSignalStrength &&
          isDndActive == other.isDndActive;

  @override
  int get hashCode => Object.hash(
        batteryLevel,
        isCharging,
        networkType,
        wifiSignalStrength,
        isDndActive,
      );

  @override
  String toString() =>
      'DeviceStatusState(battery: $batteryLevel%, charging: $isCharging, net: $networkType, dnd: $isDndActive)';
}
