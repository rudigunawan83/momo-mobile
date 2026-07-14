import 'dart:async';

/// Represents a message queued for sending when connectivity is restored.
class QueuedMessage {
  /// Unique identifier for this queued message.
  final String id;

  /// The message text content.
  final String content;

  /// The type of message: 'text' or 'voice'.
  final String type;

  /// When the message was queued.
  final DateTime queuedAt;

  const QueuedMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.queuedAt,
  });
}

/// Result of attempting to enqueue an offline message.
enum EnqueueResult {
  /// Message was successfully queued.
  success,

  /// Queue is at maximum capacity — message was not queued.
  queueFull,
}

/// Manages a queue of outgoing messages when the device is offline.
///
/// Queues up to [maxQueueSize] messages for automatic sync when
/// connectivity is restored. When the queue reaches capacity, the
/// message input should be disabled and the user informed.
///
/// Requirements: 10.7, 10.9
class OfflineMessageQueue {
  /// Maximum number of messages that can be queued offline.
  static const int maxQueueSize = 20;

  final List<QueuedMessage> _queue = [];

  final StreamController<OfflineQueueState> _stateController =
      StreamController<OfflineQueueState>.broadcast();

  /// Stream of queue state changes.
  ///
  /// Emits whenever the queue state changes (message added, synced, or
  /// capacity reached).
  Stream<OfflineQueueState> get stateStream => _stateController.stream;

  /// Current number of messages in the queue.
  int get queueLength => _queue.length;

  /// Whether the queue has reached maximum capacity.
  bool get isAtCapacity => _queue.length >= maxQueueSize;

  /// Whether there are messages waiting to be sent.
  bool get hasPendingMessages => _queue.isNotEmpty;

  /// The messages currently in the queue (read-only).
  List<QueuedMessage> get pendingMessages => List.unmodifiable(_queue);

  /// Attempts to add a message to the offline queue.
  ///
  /// Returns [EnqueueResult.success] if the message was queued.
  /// Returns [EnqueueResult.queueFull] if the queue is at capacity
  /// (the message is NOT added in this case).
  EnqueueResult enqueue(QueuedMessage message) {
    if (isAtCapacity) {
      _emitState();
      return EnqueueResult.queueFull;
    }

    _queue.add(message);
    _emitState();
    return EnqueueResult.success;
  }

  /// Removes and returns all queued messages for sync.
  ///
  /// Called when connectivity is restored to get all pending messages
  /// for delivery to the server.
  List<QueuedMessage> drainQueue() {
    final messages = List<QueuedMessage>.from(_queue);
    _queue.clear();
    _emitState();
    return messages;
  }

  /// Removes a specific message from the queue (e.g., after successful send).
  void removeMessage(String messageId) {
    _queue.removeWhere((m) => m.id == messageId);
    _emitState();
  }

  /// Clears the entire queue.
  void clear() {
    _queue.clear();
    _emitState();
  }

  /// Disposes the stream controller.
  void dispose() {
    _stateController.close();
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(OfflineQueueState(
        pendingCount: _queue.length,
        isAtCapacity: isAtCapacity,
      ));
    }
  }
}

/// Represents the current state of the offline message queue.
class OfflineQueueState {
  /// Number of messages waiting to be sent.
  final int pendingCount;

  /// Whether the queue has reached its maximum capacity.
  ///
  /// When true, message input should be disabled and the user
  /// informed that new messages cannot be sent until connectivity
  /// is restored.
  final bool isAtCapacity;

  const OfflineQueueState({
    required this.pendingCount,
    required this.isAtCapacity,
  });
}
