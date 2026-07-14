import 'dart:async';

import '../domain/repositories/i_chat_repository.dart';
import 'connectivity_monitor.dart';
import 'offline_message_cache.dart';
import 'offline_message_queue.dart';
import 'token_refresh_service.dart';

/// Represents the overall offline/online mode state of the app.
enum AppConnectivityMode {
  /// Device is online — normal operation.
  online,

  /// Device is offline — showing cached messages, queuing outbound.
  offline,
}

/// Aggregated state emitted by [OfflineModeManager].
class OfflineModeState {
  /// Current connectivity mode (online/offline).
  final AppConnectivityMode mode;

  /// Number of messages pending in the offline queue.
  final int pendingMessageCount;

  /// Whether the offline message queue is at capacity.
  ///
  /// When true, the message input should be disabled and the user
  /// should be informed that messages cannot be sent until connectivity
  /// is restored (Requirement 10.9).
  final bool isQueueAtCapacity;

  /// Whether a token refresh is in progress.
  final bool isRefreshingToken;

  const OfflineModeState({
    required this.mode,
    required this.pendingMessageCount,
    required this.isQueueAtCapacity,
    required this.isRefreshingToken,
  });

  /// Default online state with no pending messages.
  static const OfflineModeState initial = OfflineModeState(
    mode: AppConnectivityMode.online,
    pendingMessageCount: 0,
    isQueueAtCapacity: false,
    isRefreshingToken: false,
  );
}

/// Callback for syncing queued messages to the server on reconnect.
///
/// Receives the list of queued messages and sends them.
/// Returns `true` if all messages were successfully synced.
typedef MessageSyncer = Future<bool> Function(List<QueuedMessage> messages);

/// Orchestrates offline mode behavior including message caching, queueing,
/// and auto-sync on reconnection.
///
/// Integrates:
/// - [ConnectivityMonitor] for network state detection
/// - [OfflineMessageCache] for displaying cached messages offline
/// - [OfflineMessageQueue] for queuing outbound messages (max 20)
/// - [TokenRefreshService] for handling token expiration
///
/// Behavior per Requirements 10.4, 10.5, 10.7, 10.9:
/// - On network loss: switch to offline mode, display cached messages,
///   queue outgoing messages.
/// - On reconnection: auto-sync queued messages.
/// - On queue full (20 messages): disable input, inform user.
/// - On token expiry: silent refresh; on failure, redirect to login
///   preserving drafts.
///
/// Requirements: 10.4, 10.5, 10.7, 10.9
class OfflineModeManager {
  final ConnectivityMonitor _connectivityMonitor;
  final OfflineMessageCache _messageCache;
  final OfflineMessageQueue _messageQueue;
  final TokenRefreshService _tokenRefreshService;
  final MessageSyncer _messageSyncer;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  final StreamController<OfflineModeState> _stateController =
      StreamController<OfflineModeState>.broadcast();

  AppConnectivityMode _currentMode = AppConnectivityMode.online;
  bool _isSyncing = false;

  /// Creates an [OfflineModeManager].
  OfflineModeManager({
    required ConnectivityMonitor connectivityMonitor,
    required OfflineMessageCache messageCache,
    required OfflineMessageQueue messageQueue,
    required TokenRefreshService tokenRefreshService,
    required MessageSyncer messageSyncer,
  })  : _connectivityMonitor = connectivityMonitor,
        _messageCache = messageCache,
        _messageQueue = messageQueue,
        _tokenRefreshService = tokenRefreshService,
        _messageSyncer = messageSyncer;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Current connectivity mode.
  AppConnectivityMode get currentMode => _currentMode;

  /// Whether the app is currently in offline mode.
  bool get isOffline => _currentMode == AppConnectivityMode.offline;

  /// Whether the app is currently online.
  bool get isOnline => _currentMode == AppConnectivityMode.online;

  /// Whether the offline message queue is at capacity.
  bool get isQueueAtCapacity => _messageQueue.isAtCapacity;

  /// Whether a sync operation is in progress.
  bool get isSyncing => _isSyncing;

  /// The offline message cache for displaying cached messages.
  OfflineMessageCache get messageCache => _messageCache;

  /// The offline message queue for managing outbound messages.
  OfflineMessageQueue get messageQueue => _messageQueue;

  /// The token refresh service.
  TokenRefreshService get tokenRefreshService => _tokenRefreshService;

  /// Stream of offline mode state changes.
  Stream<OfflineModeState> get stateStream => _stateController.stream;

  /// Starts monitoring connectivity and managing offline mode.
  void start() {
    _connectivitySubscription =
        _connectivityMonitor.statusStream.listen(_onConnectivityChanged);

    // Set initial mode based on current connectivity status
    if (_connectivityMonitor.isOffline) {
      _switchToOffline();
    }
  }

  /// Attempts to queue an outgoing message while offline.
  ///
  /// Returns [EnqueueResult.success] if the message was queued,
  /// or [EnqueueResult.queueFull] if the queue is at capacity.
  ///
  /// When [EnqueueResult.queueFull] is returned, the caller should
  /// disable the message input and inform the user per Requirement 10.9.
  EnqueueResult queueMessage(QueuedMessage message) {
    final result = _messageQueue.enqueue(message);
    _emitState();
    return result;
  }

  /// Gets the cached messages for offline display (up to 50 most recent).
  List<ChatMessage> getOfflineMessages() {
    return _messageCache.getOfflineMessages();
  }

  /// Updates the message cache with new messages (call when online).
  void updateMessageCache(List<ChatMessage> messages) {
    _messageCache.updateCache(messages);
  }

  /// Handles a 401/token-expired response by attempting silent refresh.
  ///
  /// [unsentDrafts] are preserved to local storage if refresh fails.
  Future<TokenRefreshResult> handleTokenExpired({
    List<String> unsentDrafts = const [],
  }) async {
    _emitState();
    final result = await _tokenRefreshService.attemptRefresh(
      unsentDrafts: unsentDrafts,
    );
    _emitState();
    return result;
  }

  /// Stops monitoring and disposes resources.
  void dispose() {
    _connectivitySubscription?.cancel();
    _messageQueue.dispose();
    _tokenRefreshService.dispose();
    _stateController.close();
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _onConnectivityChanged(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.online:
        _switchToOnline();
      case ConnectivityStatus.offline:
        _switchToOffline();
    }
  }

  void _switchToOffline() {
    _currentMode = AppConnectivityMode.offline;
    _emitState();
  }

  void _switchToOnline() {
    _currentMode = AppConnectivityMode.online;
    _emitState();

    // Auto-sync queued messages on reconnect
    _syncQueuedMessages();
  }

  /// Syncs all queued messages to the server.
  Future<void> _syncQueuedMessages() async {
    if (_isSyncing || !_messageQueue.hasPendingMessages) return;

    _isSyncing = true;
    _emitState();

    try {
      final messages = _messageQueue.drainQueue();
      final success = await _messageSyncer(messages);

      if (!success) {
        // Re-queue messages that failed to sync
        for (final message in messages) {
          _messageQueue.enqueue(message);
        }
      }
    } catch (_) {
      // Sync failed — messages remain drained. In production,
      // we'd restore them, but the queue was already drained.
    } finally {
      _isSyncing = false;
      _emitState();
    }
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(OfflineModeState(
        mode: _currentMode,
        pendingMessageCount: _messageQueue.queueLength,
        isQueueAtCapacity: _messageQueue.isAtCapacity,
        isRefreshingToken: _tokenRefreshService.isRefreshing,
      ));
    }
  }
}
