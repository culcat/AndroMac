import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_crypto/bridge_crypto.dart';
import 'package:bridge_core/bridge_core.dart';
import 'sms_store.dart';

/// Feature plugin coordinating SMS reception, thread aggregation, and outbound message dispatching.
class SmsFeature implements BridgeFeature {
  @override
  final String id = 'sms';

  @override
  final Set<String> incomingTypes = const <String>{
    SmsReceivedPayload.messageType,
    SmsSentStatusPayload.messageType,
    SmsSendPayload.messageType,
  };

  final SmsStore store;

  final StreamController<SmsMessageItem> _messageReceivedController =
      StreamController<SmsMessageItem>.broadcast();
  final StreamController<SmsSentStatusPayload> _statusController =
      StreamController<SmsSentStatusPayload>.broadcast();

  FeatureContext? _context;

  /// Provider-side callback invoked on Android when Mac requests an SMS dispatch.
  void Function(SmsSendPayload payload, String messageId)? onSendRequested;

  SmsFeature({
    SmsStore? store,
    this.onSendRequested,
  }) : store = store ?? SmsStore();

  /// Stream emitting incoming SMS messages from peer.
  Stream<SmsMessageItem> get onMessageReceived =>
      _messageReceivedController.stream;

  /// Stream emitting status updates for outgoing messages.
  Stream<SmsSentStatusPayload> get onMessageStatus => _statusController.stream;

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
      case SmsReceivedPayload.messageType:
        _handleReceived(message);
        break;
      case SmsSentStatusPayload.messageType:
        _handleStatus(message);
        break;
      case SmsSendPayload.messageType:
        _handleSendRequest(message);
        break;
    }
  }

  void _handleReceived(Envelope message) {
    final payload = SmsReceivedPayload.fromMap(message.payload);

    final item = SmsMessageItem(
      id: payload.messageId,
      threadId: payload.threadId,
      address: payload.address,
      body: payload.body,
      timestamp: DateTime.fromMillisecondsSinceEpoch(payload.timestamp),
      isOutgoing: false,
      simSlot: payload.simSlot,
      status: SmsDeliveryStatus.delivered,
    );

    store.addMessage(item);
    _messageReceivedController.add(item);
  }

  void _handleStatus(Envelope message) {
    final payload = SmsSentStatusPayload.fromMap(message.payload);

    if (payload.clientMessageId != null) {
      final status = payload.success
          ? SmsDeliveryStatus.delivered
          : SmsDeliveryStatus.failed;
      store.updateMessageStatus(payload.clientMessageId!, status);
    }

    _statusController.add(payload);
  }

  void _handleSendRequest(Envelope message) {
    final payload = SmsSendPayload.fromMap(message.payload);
    onSendRequested?.call(payload, message.id);
  }

  /// Sends an SMS from Mac through the connected Android phone.
  ///
  /// Returns the assigned client message ID, or null if transport is inactive.
  String? sendSms(
    String address,
    String body, {
    int simSlot = 0,
    String? contactName,
  }) {
    if (_context == null || !_context!.isConnected) return null;

    final clientMessageId =
        'out-sms-${DateTime.now().millisecondsSinceEpoch}-${CryptoUtils.generateNumericOtp(4)}';
    final threadId = 'thread-${address.replaceAll(RegExp(r'\D'), '')}';
    final now = DateTime.now();

    final envelope = Envelope.create(
      type: SmsSendPayload.messageType,
      payload: SmsSendPayload(
        address: address,
        body: body,
        simSlot: simSlot,
        clientMessageId: clientMessageId,
      ).toMap(),
    );

    _context!.send(envelope);

    // Save locally with pending status
    final item = SmsMessageItem(
      id: clientMessageId,
      threadId: threadId,
      address: address,
      body: body,
      timestamp: now,
      isOutgoing: true,
      simSlot: simSlot,
      status: SmsDeliveryStatus.pending,
    );

    store.addMessage(item, contactName: contactName);
    return clientMessageId;
  }

  void dispose() {
    _messageReceivedController.close();
    _statusController.close();
  }
}
