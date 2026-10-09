import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';

/// Simulated macOS controller running in CLI to test Android provider integrations.
class FakeMacController {
  final String deviceId;
  final String name;
  final String appVersion;
  final List<String> capabilities;

  BridgeServer? _server;
  TransportChannel? _channel;
  final StreamController<Envelope> _incomingEvents = StreamController<Envelope>.broadcast();
  int _clipboardSeq = 0;

  FakeMacController({
    String? deviceId,
    this.name = 'Mac Studio (Fake)',
    this.appVersion = '1.0.0',
    List<String>? capabilities,
  })  : deviceId = deviceId ?? 'fake-mac-${CryptoUtils.generateNumericOtp(4)}',
        capabilities = capabilities ??
            const ['clipboard', 'notifications', 'sms', 'device_status', 'otp', 'file_transfer'];

  bool get isConnected => _channel?.isOpen ?? false;
  Stream<Envelope> get onEvent => _incomingEvents.stream;
  int get boundPort => _server?.boundPort ?? 0;

  /// Starts a local server listening for phone connections.
  Future<void> startServer({int port = 8765}) async {
    _server = BridgeServer(port: port);
    await _server!.start();

    _server!.onConnection.listen((channel) {
      attach(channel);
    });
  }

  /// Connects directly to an Android phone running in server mode.
  Future<void> connectTo(Uri uri) async {
    final channel = await BridgeClient.connect(uri);
    await attach(channel);
  }

  /// Attaches an active channel and sets up message routing.
  Future<void> attach(TransportChannel channel) async {
    _channel = channel;
    channel.incoming.listen(_handleIncomingMessage, onDone: detach);

    // Send 'hello' handshake
    final helloEnvelope = Envelope.create(
      type: HelloPayload.messageType,
      payload: HelloPayload(
        deviceId: deviceId,
        name: name,
        platform: 'macos',
        appVersion: appVersion,
        protocolVersion: 1,
        capabilities: capabilities,
      ).toMap(),
    );

    channel.send(helloEnvelope);
  }

  /// Detaches the current channel.
  Future<void> detach() async {
    await _channel?.close();
    _channel = null;
  }

  /// Stops server and cleans up connections.
  Future<void> stop() async {
    await detach();
    await _server?.stop();
    _server = null;
    await _incomingEvents.close();
  }

  void _handleIncomingMessage(Envelope envelope) {
    _incomingEvents.add(envelope);

    // Auto-respond to 'hello' with 'hello.ack'
    if (envelope.type == HelloPayload.messageType) {
      final hello = HelloPayload.fromMap(envelope.payload);
      final agreed = capabilities.where((c) => hello.capabilities.contains(c)).toList();

      final ack = Envelope.create(
        type: HelloAckPayload.messageType,
        ref: envelope.id,
        payload: HelloAckPayload(
          accepted: true,
          deviceId: deviceId,
          agreedCapabilities: agreed,
        ).toMap(),
      );
      _channel?.send(ack);
    }
  }

  /// Sends an outbound SMS request to be dispatched through the phone.
  String? sendSms(String address, String body, {int simSlot = 0}) {
    if (!isConnected) return null;
    final clientMessageId = 'fake-mac-sms-${DateTime.now().millisecondsSinceEpoch}';

    final envelope = Envelope.create(
      type: SmsSendPayload.messageType,
      payload: SmsSendPayload(
        address: address,
        body: body,
        simSlot: simSlot,
        clientMessageId: clientMessageId,
      ).toMap(),
    );

    _channel!.send(envelope);
    return clientMessageId;
  }

  /// Dismisses an active notification on the phone.
  void dismissNotification(String key) {
    if (!isConnected) return;
    final envelope = Envelope.create(
      type: NotificationDismissPayload.messageType,
      payload: NotificationDismissPayload(key: key).toMap(),
    );
    _channel!.send(envelope);
  }

  /// Sends a quick reply to an active notification on the phone.
  void replyNotification(String key, String replyText) {
    if (!isConnected) return;
    final envelope = Envelope.create(
      type: NotificationActionPayload.messageType,
      payload: NotificationActionPayload(
        key: key,
        actionId: 'action_quick_reply',
        replyText: replyText,
      ).toMap(),
    );
    _channel!.send(envelope);
  }

  /// Triggers "Find My Phone" alert ring on the phone.
  void ringPhone() {
    if (!isConnected) return;
    final envelope = Envelope.create(
      type: 'find.ring',
      payload: const <String, dynamic>{},
    );
    _channel!.send(envelope);
  }

  /// Synchronizes local clipboard text to the phone.
  void syncClipboard(String text) {
    if (!isConnected) return;
    _clipboardSeq++;
    final hash = CryptoUtils.toHex(CryptoUtils.sha256String(text));

    final envelope = Envelope.create(
      type: ClipboardPayload.messageType,
      payload: ClipboardPayload(
        mime: 'text/plain',
        data: text,
        hash: hash,
        origin: deviceId,
        seq: _clipboardSeq,
      ).toMap(),
    );

    _channel!.send(envelope);
  }
}
