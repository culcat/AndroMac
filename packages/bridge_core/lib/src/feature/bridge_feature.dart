import 'package:bridge_protocol/bridge_protocol.dart';
import 'feature_context.dart';

/// Contract that all modular AndroMac features (clipboard, notifications, SMS, etc.) must implement.
///
/// Complies with the plugin model defined in Architecture Decision Records (bridge-development-plan.md §5.4).
abstract interface class BridgeFeature {
  /// Unique identifier of the feature (e.g. 'clipboard', 'notifications', 'sms', 'device_status').
  String get id;

  /// Set of envelope message types this feature consumes (e.g. {'clipboard.update'}).
  Set<String> get incomingTypes;

  /// Called when a connection is established and the feature is activated.
  Future<void> start(FeatureContext ctx);

  /// Called when the connection drops or the feature is deactivated.
  Future<void> stop();

  /// Invoked when a matching message envelope arrives from the remote peer.
  void onMessage(Envelope message);
}
