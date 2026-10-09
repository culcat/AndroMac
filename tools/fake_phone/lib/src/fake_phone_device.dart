import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';

/// Simulated Android device running in CLI to test Mac controller integrations.
class FakePhoneDevice {
  final String deviceId;
  final String name;
  final String appVersion;
  final List<String> capabilities;

  TransportChannel? _channel;
  final StreamController<Envelope> _incomingEvents = StreamController<Envelope>.broadcast();
  int _clipboardSeq = 0;

  FakePhoneDevice({
    String? deviceId,
    this.name = 'Pixel 8 Pro (Fake)',
    this.appVersion = '1.0.0',
    List<String>? capabilities,
  })  : deviceId = deviceId ?? 'fake-phone-${CryptoUtils.generateNumericOtp(4)}',
        capabilities = capabilities ??
            const ['clipboard', 'notifications', 'sms', 'device_status'];

  bool get isConnected => _channel?.isOpen ?? false;
  Stream<Envelope> get onEvent => _incomingEvents.stream;

  /// Attaches an active transport channel and executes the initial protocol handshake.
  Future<void> attach(TransportChannel channel) async {
    _channel = channel;

    // Listen to messages from Mac
    channel.incoming.listen(_handleIncomingMessage, onDone: detach);

    // Send 'hello' handshake
    final helloEnvelope = Envelope.create(
      type: HelloPayload.messageType,
      payload: HelloPayload(
        deviceId: deviceId,
        name: name,
        platform: 'android',
        appVersion: appVersion,
        protocolVersion: 1,
        capabilities: capabilities,
      ).toMap(),
    );

    channel.send(helloEnvelope);
  }

  /// Detaches the current channel.
  void detach() {
    _channel?.close();
    _channel = null;
  }

  void _handleIncomingMessage(Envelope envelope) {
    _incomingEvents.add(envelope);

    // Auto-respond to SMS send commands with delivery status confirmation
    if (envelope.type == SmsSendPayload.messageType) {
      final smsPayload = SmsSendPayload.fromMap(envelope.payload);
      final statusEnvelope = Envelope.create(
        type: SmsSentStatusPayload.messageType,
        ref: envelope.id,
        payload: SmsSentStatusPayload(
          clientMessageId: smsPayload.clientMessageId,
          success: true,
        ).toMap(),
      );
      _channel?.send(statusEnvelope);
    }
  }

  /// Sends synthetic battery and connectivity status.
  void sendBatteryStatus({
    required int batteryLevel,
    required bool isCharging,
    String networkType = 'wifi',
  }) {
    if (!isConnected) return;
    final envelope = Envelope.create(
      type: DeviceStatusPayload.messageType,
      payload: DeviceStatusPayload(
        batteryLevel: batteryLevel,
        isCharging: isCharging,
        networkType: networkType,
        wifiSignalStrength: 4,
      ).toMap(),
    );
    _channel!.send(envelope);
  }

  /// Sends a synthetic incoming notification (e.g. WhatsApp, Telegram).
  void sendNotification({
    required String appName,
    required String packageName,
    required String title,
    required String text,
    bool canReply = true,
  }) {
    if (!isConnected) return;
    final key = '$packageName|${DateTime.now().millisecondsSinceEpoch}|null';
    final envelope = Envelope.create(
      type: NotificationPostedPayload.messageTypePosted,
      payload: NotificationPostedPayload(
        key: key,
        packageName: packageName,
        appName: appName,
        title: title,
        text: text,
        postTime: DateTime.now().millisecondsSinceEpoch,
        canReply: canReply,
        actions: [
          if (canReply)
            const NotificationAction(
              actionId: 'action_quick_reply',
              title: 'Reply',
              isQuickReply: true,
            ),
        ],
      ).toMap(),
    );
    _channel!.send(envelope);
  }

  /// Sends a synthetic incoming SMS message.
  void sendSms({
    required String address,
    required String body,
    int simSlot = 0,
  }) {
    if (!isConnected) return;
    final envelope = Envelope.create(
      type: SmsReceivedPayload.messageType,
      payload: SmsReceivedPayload(
        messageId: 'fake-sms-${DateTime.now().millisecondsSinceEpoch}',
        threadId: 'thread-${address.hashCode}',
        address: address,
        body: body,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        simSlot: simSlot,
      ).toMap(),
    );
    _channel!.send(envelope);
  }

  /// Sends a synthetic clipboard update.
  void sendClipboard(String content) {
    if (!isConnected) return;
    _clipboardSeq++;
    final hash = CryptoUtils.toHex(CryptoUtils.sha256String(content));
    final envelope = Envelope.create(
      type: ClipboardPayload.messageType,
      payload: ClipboardPayload(
        mime: 'text/plain',
        data: content,
        hash: hash,
        origin: deviceId,
        seq: _clipboardSeq,
      ).toMap(),
    );
    _channel!.send(envelope);
  }
}
