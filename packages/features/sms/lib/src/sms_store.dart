import 'package:bridge_core/bridge_core.dart';

/// In-memory storage and conversation aggregator for SMS threads and messages.
class SmsStore {
  final Map<String, SmsThreadItem> _threads = <String, SmsThreadItem>{};
  final Map<String, List<SmsMessageItem>> _messagesByThread = <String, List<SmsMessageItem>>{};

  /// Read-only list of conversation threads sorted by most recent message.
  List<SmsThreadItem> get threads {
    final list = _threads.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  /// Total count of conversation threads.
  int get threadCount => _threads.length;

  /// Retrieves chronological messages for a specific [threadId].
  List<SmsMessageItem> getMessages(String threadId) {
    final list = _messagesByThread[threadId];
    if (list == null) return const <SmsMessageItem>[];
    return List.unmodifiable(list);
  }

  /// Inserts a new message and updates the parent thread summary.
  void addMessage(SmsMessageItem message, {String? contactName}) {
    final threadList = _messagesByThread.putIfAbsent(message.threadId, () => <SmsMessageItem>[]);
    // Deduplicate by message ID
    threadList.removeWhere((m) => m.id == message.id);
    threadList.add(message);
    threadList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final existingThread = _threads[message.threadId];
    final unread = (existingThread?.unreadCount ?? 0) + (message.isOutgoing ? 0 : 1);

    _threads[message.threadId] = SmsThreadItem(
      threadId: message.threadId,
      address: message.address,
      contactName: contactName ?? existingThread?.contactName,
      lastMessage: message,
      unreadCount: unread,
      updatedAt: message.timestamp,
    );
  }

  /// Marks all messages in [threadId] as read.
  void markThreadRead(String threadId) {
    final thread = _threads[threadId];
    if (thread != null && thread.unreadCount > 0) {
      _threads[threadId] = SmsThreadItem(
        threadId: thread.threadId,
        address: thread.address,
        contactName: thread.contactName,
        lastMessage: thread.lastMessage,
        unreadCount: 0,
        updatedAt: thread.updatedAt,
      );
    }
  }

  /// Updates delivery status of an outgoing message.
  void updateMessageStatus(String messageId, SmsDeliveryStatus status) {
    for (final threadMessages in _messagesByThread.values) {
      final index = threadMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final current = threadMessages[index];
        final updated = SmsMessageItem(
          id: current.id,
          threadId: current.threadId,
          address: current.address,
          body: current.body,
          timestamp: current.timestamp,
          isOutgoing: current.isOutgoing,
          simSlot: current.simSlot,
          status: status,
        );
        threadMessages[index] = updated;

        // If this was the thread's last message, update the thread summary as well
        final thread = _threads[current.threadId];
        if (thread?.lastMessage?.id == messageId) {
          _threads[current.threadId] = SmsThreadItem(
            threadId: thread!.threadId,
            address: thread.address,
            contactName: thread.contactName,
            lastMessage: updated,
            unreadCount: thread.unreadCount,
            updatedAt: thread.updatedAt,
          );
        }
        break;
      }
    }
  }

  /// Filters threads by search query matching contact name, address, or message body.
  List<SmsThreadItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return threads;

    return threads.where((t) {
      if (t.displayName.toLowerCase().contains(q)) return true;
      if (t.address.toLowerCase().contains(q)) return true;
      if (t.lastMessage?.body.toLowerCase().contains(q) ?? false) return true;
      return false;
    }).toList();
  }

  /// Clears all threads and messages.
  void clear() {
    _threads.clear();
    _messagesByThread.clear();
  }
}
