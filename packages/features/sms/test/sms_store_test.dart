import 'package:test/test.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:sms_feature/sms_feature.dart';

void main() {
  group('SmsStore', () {
    test('addMessage aggregates messages under threadId and updates summary',
        () {
      final store = SmsStore();
      final now = DateTime.now();

      final msg1 = SmsMessageItem(
        id: 'msg-1',
        threadId: 'thread-100',
        address: '+15551234567',
        body: 'First message',
        timestamp: now.subtract(const Duration(minutes: 5)),
      );

      final msg2 = SmsMessageItem(
        id: 'msg-2',
        threadId: 'thread-100',
        address: '+15551234567',
        body: 'Second message',
        timestamp: now,
      );

      store.addMessage(msg1, contactName: 'John Doe');
      expect(store.threadCount, equals(1));
      expect(store.threads.first.unreadCount, equals(1));
      expect(store.threads.first.contactName, equals('John Doe'));

      store.addMessage(msg2);
      expect(store.threadCount, equals(1));
      expect(store.threads.first.unreadCount, equals(2));
      expect(store.threads.first.lastMessage?.body, equals('Second message'));

      final threadMessages = store.getMessages('thread-100');
      expect(threadMessages.length, equals(2));
      expect(threadMessages.first.id, equals('msg-1'));
      expect(threadMessages.last.id, equals('msg-2'));
    });

    test('markThreadRead resets unread count to 0', () {
      final store = SmsStore();
      final msg = SmsMessageItem(
        id: 'msg-1',
        threadId: 'thread-200',
        address: '+15559876543',
        body: 'Unread message',
        timestamp: DateTime.now(),
      );

      store.addMessage(msg);
      expect(store.threads.first.unreadCount, equals(1));

      store.markThreadRead('thread-200');
      expect(store.threads.first.unreadCount, equals(0));
    });

    test('updateMessageStatus updates status and thread summary', () {
      final store = SmsStore();
      final outgoingMsg = SmsMessageItem(
        id: 'client-out-1',
        threadId: 'thread-300',
        address: '+15550001111',
        body: 'Sent from Mac',
        timestamp: DateTime.now(),
        isOutgoing: true,
        status: SmsDeliveryStatus.pending,
      );

      store.addMessage(outgoingMsg);
      expect(store.getMessages('thread-300').first.status,
          equals(SmsDeliveryStatus.pending));

      store.updateMessageStatus('client-out-1', SmsDeliveryStatus.delivered);
      expect(store.getMessages('thread-300').first.status,
          equals(SmsDeliveryStatus.delivered));
      expect(store.threads.first.lastMessage?.status,
          equals(SmsDeliveryStatus.delivered));
    });

    test('search filters threads by name, address, or body', () {
      final store = SmsStore();
      final now = DateTime.now();

      store.addMessage(
        SmsMessageItem(
          id: '1',
          threadId: 't1',
          address: '+1234',
          body: 'Bank confirmation code: 7788',
          timestamp: now,
        ),
        contactName: 'Bank Alert',
      );

      store.addMessage(
        SmsMessageItem(
          id: '2',
          threadId: 't2',
          address: '+5678',
          body: 'Dinner plans tonight?',
          timestamp: now,
        ),
        contactName: 'Sarah',
      );

      expect(store.search('Bank').length, equals(1));
      expect(store.search('Bank').first.displayName, equals('Bank Alert'));

      expect(store.search('7788').length, equals(1));
      expect(store.search('5678').length, equals(1));
      expect(store.search('dinner').length, equals(1));
      expect(store.search('nonexistent'), isEmpty);
    });
  });
}
