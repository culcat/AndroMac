import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_core/bridge_core.dart';
import 'clipboard_history_store.dart';

/// Feature plugin coordinating bidirectional clipboard synchronization with loopback prevention.
class ClipboardFeature implements BridgeFeature {
  @override
  final String id = 'clipboard';

  @override
  final Set<String> incomingTypes = const <String>{ClipboardPayload.messageType};

  final String localDeviceId;
  final ClipboardHistoryStore history;
  final StreamController<ClipboardItem> _changeController =
      StreamController<ClipboardItem>.broadcast();

  FeatureContext? _context;
  String? _lastSentHash;
  String? _lastReceivedHash;
  int _sequence = 0;

  ClipboardFeature({
    required this.localDeviceId,
    ClipboardHistoryStore? historyStore,
  }) : history = historyStore ?? ClipboardHistoryStore();

  /// Stream emitting new clipboard items (both local copies and remote updates).
  Stream<ClipboardItem> get onClipboardChanged => _changeController.stream;

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
    if (message.type != ClipboardPayload.messageType) return;

    final payload = ClipboardPayload.fromMap(message.payload);

    // Suppress loopback echoes: ignore if this is our own update reflected back
    if (payload.origin == localDeviceId || payload.hash == _lastSentHash) {
      return;
    }

    // Suppress duplicates
    if (payload.hash == _lastReceivedHash) {
      return;
    }

    _lastReceivedHash = payload.hash;

    final item = ClipboardItem(
      id: message.id,
      mime: payload.mime,
      content: payload.data,
      hash: payload.hash,
      originDeviceId: payload.origin,
      timestamp: DateTime.fromMillisecondsSinceEpoch(message.ts),
    );

    history.add(item);
    _changeController.add(item);
  }

  /// Sends local clipboard content to the connected remote peer.
  ///
  /// Returns false if skipped due to duplicate hash or inactive connection.
  bool syncOutbound(String text, {String mime = 'text/plain'}) {
    if (_context == null || !_context!.isConnected) return false;

    final hash = CryptoUtils.toHex(CryptoUtils.sha256String(text));

    // Avoid redundant transmission if identical to our last sent or received item
    if (hash == _lastSentHash || hash == _lastReceivedHash) {
      return false;
    }

    _lastSentHash = hash;
    _sequence++;

    final now = DateTime.now();
    final envelope = Envelope.create(
      type: ClipboardPayload.messageType,
      timestampMs: now.millisecondsSinceEpoch,
      payload: ClipboardPayload(
        mime: mime,
        data: text,
        hash: hash,
        origin: localDeviceId,
        seq: _sequence,
      ).toMap(),
    );

    _context!.send(envelope);

    final item = ClipboardItem(
      id: envelope.id,
      mime: mime,
      content: text,
      hash: hash,
      originDeviceId: localDeviceId,
      timestamp: now,
    );

    history.add(item);
    _changeController.add(item);

    return true;
  }

  void dispose() {
    _changeController.close();
  }
}
