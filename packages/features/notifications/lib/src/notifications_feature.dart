import 'dart:async';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_core/bridge_core.dart';
import 'notification_filter.dart';
import 'notification_store.dart';

/// Feature plugin coordinating notification mirroring, dismiss synchronization, and quick replies.
class NotificationsFeature implements BridgeFeature {
  @override
  final String id = 'notifications';

  @override
  final Set<String> incomingTypes = const <String>{
    NotificationPostedPayload.messageTypePosted,
    NotificationPostedPayload.messageTypeUpdated,
    NotificationDismissPayload.messageType,
    NotificationActionPayload.messageType,
  };

  final NotificationFilter filter;
  final NotificationStore store;

  final StreamController<NotificationItem> _notificationStream =
      StreamController<NotificationItem>.broadcast();
  final StreamController<String> _dismissStream =
      StreamController<String>.broadcast();

  FeatureContext? _context;

  /// Callback executed on Android provider when Mac user triggers an action / quick reply.
  void Function(String key, String actionId, String? replyText)?
      onActionRequested;

  NotificationsFeature({
    NotificationFilter? filter,
    NotificationStore? store,
    this.onActionRequested,
  })  : filter = filter ?? NotificationFilter(),
        store = store ?? NotificationStore();

  /// Stream of active mirrored notification updates.
  Stream<NotificationItem> get onNotification => _notificationStream.stream;

  /// Stream of notification keys dismissed by peer.
  Stream<String> get onDismissed => _dismissStream.stream;

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
      case NotificationPostedPayload.messageTypePosted:
      case NotificationPostedPayload.messageTypeUpdated:
        _handlePostedOrUpdated(message);
        break;
      case NotificationDismissPayload.messageType:
        _handleDismiss(message);
        break;
      case NotificationActionPayload.messageType:
        _handleAction(message);
        break;
    }
  }

  void _handlePostedOrUpdated(Envelope message) {
    final payload = NotificationPostedPayload.fromMap(message.payload);

    // Apply filtering rules
    if (!filter.shouldMirror(payload)) {
      return;
    }

    final actions = payload.actions
        .map(
          (a) => NotificationActionItem(
            actionId: a.actionId,
            title: a.title,
            isQuickReply: a.isQuickReply,
          ),
        )
        .toList();

    final item = NotificationItem(
      key: payload.key,
      packageName: payload.packageName,
      appName: payload.appName,
      title: payload.title,
      text: payload.text,
      postedAt: DateTime.fromMillisecondsSinceEpoch(payload.postTime),
      canReply: payload.canReply,
      actions: actions,
    );

    store.addOrUpdate(item);
    _notificationStream.add(item);
  }

  void _handleDismiss(Envelope message) {
    final payload = NotificationDismissPayload.fromMap(message.payload);
    store.markDismissed(payload.key);
    _dismissStream.add(payload.key);
  }

  void _handleAction(Envelope message) {
    final payload = NotificationActionPayload.fromMap(message.payload);
    onActionRequested?.call(payload.key, payload.actionId, payload.replyText);
  }

  /// Sends a dismiss command from Mac to Phone.
  bool dismissNotification(String key) {
    if (_context == null || !_context!.isConnected) return false;

    final envelope = Envelope.create(
      type: NotificationDismissPayload.messageType,
      payload: NotificationDismissPayload(key: key).toMap(),
    );

    _context!.send(envelope);
    store.markDismissed(key);
    _dismissStream.add(key);
    return true;
  }

  /// Sends an inline reply or action click from Mac to Phone.
  bool replyToNotification(
    String key,
    String replyText, {
    String actionId = 'action_quick_reply',
  }) {
    if (_context == null || !_context!.isConnected) return false;

    final envelope = Envelope.create(
      type: NotificationActionPayload.messageType,
      payload: NotificationActionPayload(
        key: key,
        actionId: actionId,
        replyText: replyText,
      ).toMap(),
    );

    _context!.send(envelope);
    return true;
  }

  /// Dispatches a local Android notification across to Mac.
  void postNotification(NotificationItem item) {
    if (filter.shouldFilter(item.packageName, isOngoing: false)) return;

    store.addOrUpdate(item);
    _notificationStream.add(item);

    if (_context != null && _context!.isConnected) {
      final envelope = Envelope.create(
        type: NotificationPostedPayload.messageTypePosted,
        payload: NotificationPostedPayload(
          key: item.key,
          packageName: item.packageName,
          appName: item.appName,
          title: item.title,
          text: item.text,
          postTime: item.postedAt.millisecondsSinceEpoch,
          canReply: item.canReply,
          actions: item.actions
              .map(
                (a) => NotificationAction(
                  actionId: a.actionId,
                  title: a.title,
                  isQuickReply: a.isQuickReply,
                ),
              )
              .toList(),
        ).toMap(),
      );
      _context!.send(envelope);
    }
  }

  void dispose() {
    _notificationStream.close();
    _dismissStream.close();
  }
}
