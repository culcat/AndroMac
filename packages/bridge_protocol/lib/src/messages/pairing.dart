import 'package:meta/meta.dart';

/// Payload for 'pair.request' (initiating pairing).
@immutable
class PairRequestPayload {
  static const String messageType = 'pair.request';

  final String deviceId;
  final String deviceName;
  final String publicKeyFingerprint;
  final String pairingCode; // One-time code from QR or manual input

  const PairRequestPayload({
    required this.deviceId,
    required this.deviceName,
    required this.publicKeyFingerprint,
    required this.pairingCode,
  });

  factory PairRequestPayload.fromMap(Map<String, dynamic> map) {
    return PairRequestPayload(
      deviceId: map['deviceId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      publicKeyFingerprint: map['publicKeyFingerprint'] as String? ?? '',
      pairingCode: map['pairingCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'deviceName': deviceName,
      'publicKeyFingerprint': publicKeyFingerprint,
      'pairingCode': pairingCode,
    };
  }
}

/// Payload for 'pair.accept' (responder accepts pairing and shows SAS).
@immutable
class PairAcceptPayload {
  static const String messageType = 'pair.accept';

  final String deviceId;
  final String deviceName;
  final String
      sasCode; // Short Authentication String (e.g. 6-digit number or emojis)
  final String publicKeyFingerprint;

  const PairAcceptPayload({
    required this.deviceId,
    required this.deviceName,
    required this.sasCode,
    required this.publicKeyFingerprint,
  });

  factory PairAcceptPayload.fromMap(Map<String, dynamic> map) {
    return PairAcceptPayload(
      deviceId: map['deviceId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      sasCode: map['sasCode'] as String? ?? '',
      publicKeyFingerprint: map['publicKeyFingerprint'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'deviceName': deviceName,
      'sasCode': sasCode,
      'publicKeyFingerprint': publicKeyFingerprint,
    };
  }
}

/// Payload for 'pair.confirm' (both users verified SAS and confirmed).
@immutable
class PairConfirmPayload {
  static const String messageType = 'pair.confirm';

  final bool confirmed;

  const PairConfirmPayload({required this.confirmed});

  factory PairConfirmPayload.fromMap(Map<String, dynamic> map) {
    return PairConfirmPayload(
      confirmed: map['confirmed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'confirmed': confirmed,
    };
  }
}

/// Payload for 'pair.reject' (pairing rejected or cancelled).
@immutable
class PairRejectPayload {
  static const String messageType = 'pair.reject';

  final String reason;

  const PairRejectPayload({required this.reason});

  factory PairRejectPayload.fromMap(Map<String, dynamic> map) {
    return PairRejectPayload(
      reason: map['reason'] as String? ?? 'Pairing rejected',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'reason': reason,
    };
  }
}
