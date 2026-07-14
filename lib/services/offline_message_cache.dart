import '../domain/repositories/i_chat_repository.dart';

/// Provides access to the most recent messages from local cache
/// when the device is offline.
///
/// Stores up to [maxCachedMessages] messages for offline display.
/// Messages are stored in memory and optionally persisted to local storage.
///
/// Requirements: 10.7
class OfflineMessageCache {
  /// Maximum number of messages to retain in offline cache.
  static const int maxCachedMessages = 50;

  final List<ChatMessage> _cachedMessages = [];

  /// The currently cached messages (most recent first).
  List<ChatMessage> get messages => List.unmodifiable(_cachedMessages);

  /// Number of messages currently in cache.
  int get messageCount => _cachedMessages.length;

  /// Updates the offline cache with the latest messages.
  ///
  /// Typically called after receiving new messages from the server
  /// or loading from persistent storage. Retains only the most recent
  /// [maxCachedMessages] messages.
  void updateCache(List<ChatMessage> messages) {
    _cachedMessages.clear();
    if (messages.length > maxCachedMessages) {
      _cachedMessages.addAll(messages.sublist(0, maxCachedMessages));
    } else {
      _cachedMessages.addAll(messages);
    }
  }

  /// Adds a single message to the cache (e.g., a locally sent message).
  ///
  /// If the cache exceeds [maxCachedMessages], the oldest message is removed.
  void addMessage(ChatMessage message) {
    _cachedMessages.insert(0, message);
    if (_cachedMessages.length > maxCachedMessages) {
      _cachedMessages.removeLast();
    }
  }

  /// Returns up to [maxCachedMessages] messages for offline display.
  List<ChatMessage> getOfflineMessages() {
    return List.unmodifiable(_cachedMessages);
  }

  /// Clears the entire offline message cache.
  void clear() {
    _cachedMessages.clear();
  }
}
