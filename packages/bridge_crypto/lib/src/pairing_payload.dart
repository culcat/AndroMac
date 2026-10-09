import 'dart:convert';
import 'package:meta/meta.dart';
import 'certificate_pin.dart';
import 'crypto_utils.dart';

/// Data model representing the payload encoded in the pairing QR code.
@immutable
class BridgePairingData {
  static const int currentVersion = 1;
  static const int defaultTtlSeconds = 120; // 2 minutes QR lifespan

  final int v;
  final String deviceId;
  final String name;
  final List<String> ips;
  final int port;
  final String fingerprint; // Normalized SHA-256 cert fingerprint
  final String pairingCode; // 6-digit OTP code
  final int expiresAt; // Epoch milliseconds

  const BridgePairingData({
    this.v = currentVersion,
    required this.deviceId,
    required this.name,
    required this.ips,
    required this.port,
    required this.fingerprint,
    required this.pairingCode,
    required this.expiresAt,
  });

  /// Factory to create new pairing data with automatic expiration.
  factory BridgePairingData.create({
    required String deviceId,
    required String name,
    required List<String> ips,
    required int port,
    required String fingerprint,
    String? pairingCode,
    int ttlSeconds = defaultTtlSeconds,
    int? nowMs,
  }) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return BridgePairingData(
      v: currentVersion,
      deviceId: deviceId,
      name: name,
      ips: List<String>.unmodifiable(ips),
      port: port,
      fingerprint: CertificateFingerprint.normalize(fingerprint),
      pairingCode: pairingCode ?? CryptoUtils.generateNumericOtp(6),
      expiresAt: now + (ttlSeconds * 1000),
    );
  }

  /// Whether the pairing code has expired.
  bool isExpired([int? nowMs]) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return now >= expiresAt;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'v': v,
      'id': deviceId,
      'name': name,
      'ips': ips,
      'port': port,
      'fp': fingerprint,
      'code': pairingCode,
      'exp': expiresAt,
    };
  }

  /// Serializes to JSON string for QR code generation.
  String encodeJson() => jsonEncode(toMap());

  /// Serializes to compact custom URI scheme: andromac://pair?data=...
  String encodeUri() {
    final base64Json = base64Url.encode(utf8.encode(encodeJson()));
    return 'andromac://pair?data=$base64Json';
  }

  /// Deserializes from a map.
  factory BridgePairingData.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('id') || !map.containsKey('fp') || !map.containsKey('code')) {
      throw const FormatException('Missing required fields in BridgePairingData');
    }

    final rawIps = map['ips'];
    final List<String> ipsList;
    if (rawIps is List) {
      ipsList = rawIps.map((e) => e.toString()).toList();
    } else {
      ipsList = const <String>[];
    }

    return BridgePairingData(
      v: map['v'] as int? ?? currentVersion,
      deviceId: map['id'] as String,
      name: map['name'] as String? ?? 'Device',
      ips: List<String>.unmodifiable(ipsList),
      port: map['port'] as int? ?? 8765,
      fingerprint: CertificateFingerprint.normalize(map['fp'] as String),
      pairingCode: map['code'] as String,
      expiresAt: map['exp'] as int? ?? 0,
    );
  }

  /// Deserializes from JSON string or andromac://pair URI.
  factory BridgePairingData.decode(String raw) {
    var payload = raw.trim();
    if (payload.startsWith('andromac://pair?data=')) {
      final b64 = payload.substring('andromac://pair?data='.length);
      final jsonStr = utf8.decode(base64Url.decode(b64));
      return BridgePairingData.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
    }

    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Decoded pairing data must be a JSON object');
    }
    return BridgePairingData.fromMap(decoded);
  }
}
