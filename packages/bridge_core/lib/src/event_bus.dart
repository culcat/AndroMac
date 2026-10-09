import 'dart:async';

/// Lightweight in-process event bus for decoupling domain events from UI consumers.
class EventBus {
  final StreamController<dynamic> _streamController;

  EventBus({bool sync = false})
      : _streamController = StreamController<dynamic>.broadcast(sync: sync);

  /// Emits an event to all subscribers.
  void emit<T>(T event) {
    if (!_streamController.isClosed) {
      _streamController.add(event);
    }
  }

  /// Subscribes to events of specific type [T].
  Stream<T> on<T>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  /// Closes the event stream.
  void dispose() {
    _streamController.close();
  }
}
