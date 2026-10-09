import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_core/bridge_core.dart';
import 'remote_control_model.dart';

/// Feature plugin coordinating screen control setup, hardware button triggers, and normalized input gestures.
class RemoteControlFeature implements BridgeFeature {
  static const String typeSetupRequest = 'remote.setup.request';
  static const String typeSetupStatus = 'remote.setup.status';
  static const String typeInput = 'remote.control.input';
  static const String typeNav = 'remote.control.nav';

  @override
  final String id = 'remote_control';

  @override
  final Set<String> incomingTypes = const <String>{
    typeSetupRequest,
    typeSetupStatus,
    typeInput,
    typeNav,
  };

  final StreamController<RemoteInputEvent> _inputController =
      StreamController<RemoteInputEvent>.broadcast();
  final StreamController<AndroidNavButton> _navController =
      StreamController<AndroidNavButton>.broadcast();

  FeatureContext? _context;

  /// Provider-side callbacks invoked on Android when user sends mouse/touch or nav actions from Mac
  void Function(RemoteInputEvent event)? onInputReceived;
  void Function(AndroidNavButton button)? onNavButtonReceived;

  RemoteControlFeature({
    this.onInputReceived,
    this.onNavButtonReceived,
  });

  /// Stream of received input gestures.
  Stream<RemoteInputEvent> get onInput => _inputController.stream;

  /// Stream of received navigation button presses.
  Stream<AndroidNavButton> get onNavButton => _navController.stream;

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
    switch (message.type) {
      case typeInput:
        final event = RemoteInputEvent.fromMap(message.payload);
        _inputController.add(event);
        onInputReceived?.call(event);
        break;
      case typeNav:
        final buttonName = message.payload['button'] as String? ?? 'back';
        final button = AndroidNavButton.fromString(buttonName);
        _navController.add(button);
        onNavButtonReceived?.call(button);
        break;
      case typeSetupRequest:
        // Handle setup / profile configuration request on Android
        break;
      case typeSetupStatus:
        // Handle status / ready update on Mac
        break;
    }
  }

  /// Sends a normalized touch, click, or scroll gesture from Mac to phone.
  bool sendInput(RemoteInputEvent event) {
    if (_context == null || !_context!.isConnected) return false;

    final envelope = Envelope.create(
      type: typeInput,
      payload: event.toMap(),
    );

    _context!.send(envelope);
    return true;
  }

  /// Sends a hardware navigation button press (Back, Home, Recents, Volume, Power) from Mac.
  bool sendNavButton(AndroidNavButton button) {
    if (_context == null || !_context!.isConnected) return false;

    final envelope = Envelope.create(
      type: typeNav,
      payload: <String, dynamic>{'button': button.name},
    );

    _context!.send(envelope);
    return true;
  }

  /// Sends setup negotiation parameters with desired streaming quality.
  bool requestSetup({RemoteControlProfile profile = const RemoteControlProfile()}) {
    if (_context == null || !_context!.isConnected) return false;

    final envelope = Envelope.create(
      type: typeSetupRequest,
      payload: profile.toMap(),
    );

    _context!.send(envelope);
    return true;
  }

  void dispose() {
    _inputController.close();
    _navController.close();
  }
}
