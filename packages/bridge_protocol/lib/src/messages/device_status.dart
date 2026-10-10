import 'package:meta/meta.dart';

/// Payload for 'device.status' telemetry message.
@immutable
class DeviceStatusPayload {
  static const String messageType = 'device.status';

  final int batteryLevel; // 0 - 100
  final bool isCharging;
  final String networkType; // 'wifi' | 'cellular' | 'ethernet' | 'none'
  final int? wifiSignalStrength; // 0 - 4
  final bool isDndActive; // Do Not Disturb status

  int? get signalStrength => wifiSignalStrength;

  const DeviceStatusPayload({
    required this.batteryLevel,
    required this.isCharging,
    required this.networkType,
    int? wifiSignalStrength,
    int? signalStrength,
    this.isDndActive = false,
  }) : wifiSignalStrength = wifiSignalStrength ?? signalStrength;

  factory DeviceStatusPayload.fromMap(Map<String, dynamic> map) {
    return DeviceStatusPayload(
      batteryLevel: map['batteryLevel'] as int? ?? 0,
      isCharging: map['isCharging'] as bool? ?? false,
      networkType: map['networkType'] as String? ?? 'none',
      wifiSignalStrength:
          (map['wifiSignalStrength'] ?? map['signalStrength']) as int?,
      isDndActive: map['isDndActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'networkType': networkType,
      if (wifiSignalStrength != null) 'wifiSignalStrength': wifiSignalStrength,
      'isDndActive': isDndActive,
    };
  }
}
