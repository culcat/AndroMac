import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'bridge_feature.dart';
import 'feature_context.dart';

/// Central registry managing lifecycle, capability negotiation, and message routing for [BridgeFeature]s.
class FeatureRegistry {
  final Map<String, BridgeFeature> _features = <String, BridgeFeature>{};
  final Map<String, Set<BridgeFeature>> _typeRouting = <String, Set<BridgeFeature>>{};
  final Set<String> _activeFeatureIds = <String>{};

  /// Registers a feature plugin.
  void register(BridgeFeature feature) {
    if (_features.containsKey(feature.id)) {
      throw ArgumentError('Feature with id "${feature.id}" is already registered');
    }
    _features[feature.id] = feature;

    for (final type in feature.incomingTypes) {
      _typeRouting.putIfAbsent(type, () => <BridgeFeature>{}).add(feature);
    }
  }

  /// Unregisters a feature plugin.
  void unregister(String featureId) {
    final feature = _features.remove(featureId);
    if (feature != null) {
      for (final type in feature.incomingTypes) {
        _typeRouting[type]?.remove(feature);
      }
      _activeFeatureIds.remove(featureId);
    }
  }

  /// Returns list of all locally registered feature IDs to advertise in 'hello' capabilities.
  List<String> get supportedCapabilities => _features.keys.toList();

  /// Returns set of IDs of currently active features.
  Set<String> get activeFeatureIds => Set.unmodifiable(_activeFeatureIds);

  /// Activates features agreed upon during capability negotiation with remote peer.
  Future<void> startAgreedFeatures(
    FeatureContext context,
    List<String> peerCapabilities,
  ) async {
    final agreed = peerCapabilities.toSet();

    for (final entry in _features.entries) {
      if (agreed.contains(entry.key)) {
        try {
          await entry.value.start(context);
          _activeFeatureIds.add(entry.key);
        } catch (e) {
          // Log or isolate feature startup failures
        }
      }
    }
  }

  /// Deactivates all currently active features.
  Future<void> stopAll() async {
    for (final id in _activeFeatureIds.toList()) {
      final feature = _features[id];
      if (feature != null) {
        try {
          await feature.stop();
        } catch (_) {}
      }
    }
    _activeFeatureIds.clear();
  }

  /// Routes an incoming envelope to all active features registered for [message.type].
  void dispatch(Envelope message) {
    final targets = _typeRouting[message.type];
    if (targets == null || targets.isEmpty) return;

    for (final feature in targets) {
      if (_activeFeatureIds.contains(feature.id)) {
        try {
          feature.onMessage(message);
        } catch (e) {
          // Feature handler exception isolated
        }
      }
    }
  }
}
