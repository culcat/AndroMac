import 'dart:async';
import 'package:test/test.dart';
import 'package:bridge_protocol/bridge_protocol.dart';
import 'package:bridge_transport/bridge_transport.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:notifications_feature/notifications_feature.dart';

class MockTransportChannel implements TransportChannel {
  final _incoming = StreamController<Envelope>.broadcast();
  final List<Envelope> sent = <Envelope>[];
  bool _open = true;

  @override
  Stream<Envelope> get incoming => _incoming.stream;

  @override
  bool get isOpen => _open;

  @override
  void send(Envelope envelope) {
    sent.add(envelope);
  }

  @override
  Future<void> close() async {
    _open = false;
    await _incoming.close();
  }
}

void main() {
  group('NotificationsFeature', () {
    test('filters out blacklisted system packages', () async {
      final feature = NotificationsFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final events = <NotificationItem>[];
      feature.onNotification.listen(events.add);

      // System notification (should be blocked)
      final systemNotif = Envelope.create(
        type: NotificationPostedPayload.messageTypePosted,
        payload: const NotificationPostedPayload(
          key: 'android|100|null',
          packageName: 'com.android.systemui',
          appName: 'System UI',
          title: 'USB debugging connected',
          text: 'Tap to disable',
          postTime: 1760000000000,
        ).toMap(),
      );

      feature.onMessage(systemNotif);
      expect(events, isEmpty);
      expect(feature.store.count, equals(0));

      // User notification (should be accepted)
      final userNotif = Envelope.create(
        type: NotificationPostedPayload.messageTypePosted,
        payload: const NotificationPostedPayload(
          key: 'org.telegram.messenger|101|null',
          packageName: 'org.telegram.messenger',
          appName: 'Telegram',
          title: 'Daria',
          text: 'See you tomorrow!',
          postTime: 1760000000000,
          canReply: true,
        ).toMap(),
      );

      feature.onMessage(userNotif);
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(1));
      expect(feature.store.count, equals(1));
      expect(
          feature.store.activeNotifications.first.appName, equals('Telegram'));
    });

    test('dismissNotification sends envelope and marks item dismissed in store',
        () async {
      final feature = NotificationsFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      // Populate store with an active notification
      final userNotif = Envelope.create(
        type: NotificationPostedPayload.messageTypePosted,
        payload: const NotificationPostedPayload(
          key: 'notif-key-1',
          packageName: 'com.whatsapp',
          appName: 'WhatsApp',
          title: 'Work',
          text: 'Meeting at 10',
          postTime: 1760000000000,
        ).toMap(),
      );
      feature.onMessage(userNotif);
      expect(feature.store.count, equals(1));

      // Mac user dismisses it
      final success = feature.dismissNotification('notif-key-1');
      expect(success, isTrue);
      expect(channel.sent.length, equals(1));
      expect(channel.sent.first.type,
          equals(NotificationDismissPayload.messageType));

      // Active count should now be 0
      expect(feature.store.count, equals(0));
    });

    test('replyToNotification sends notif.action with replyText', () async {
      final feature = NotificationsFeature();
      final channel = MockTransportChannel();
      final context = FeatureContext(peerDeviceId: 'phone-1', channel: channel);
      await feature.start(context);

      final success = feature.replyToNotification('notif-key-2', 'Thanks!');
      expect(success, isTrue);
      expect(channel.sent.length, equals(1));

      final sentEnvelope = channel.sent.first;
      expect(sentEnvelope.type, equals(NotificationActionPayload.messageType));
      final payload = NotificationActionPayload.fromMap(sentEnvelope.payload);
      expect(payload.key, equals('notif-key-2'));
      expect(payload.replyText, equals('Thanks!'));
    });

    test('receiving notif.action invokes onActionRequested callback on Android',
        () async {
      String? receivedKey;
      String? receivedReply;

      final feature = NotificationsFeature(
        onActionRequested: (key, actionId, replyText) {
          receivedKey = key;
          receivedReply = replyText;
        },
      );

      final actionEnvelope = Envelope.create(
        type: NotificationActionPayload.messageType,
        payload: const NotificationActionPayload(
          key: 'remote-key-99',
          actionId: 'action_quick_reply',
          replyText: 'Got it!',
        ).toMap(),
      );

      feature.onMessage(actionEnvelope);

      expect(receivedKey, equals('remote-key-99'));
      expect(receivedReply, equals('Got it!'));
    });
  });
}
