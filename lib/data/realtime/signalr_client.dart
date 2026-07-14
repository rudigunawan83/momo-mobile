import 'dart:async';
import 'dart:math';

import 'package:signalr_netcore/signalr_client.dart';

import 'connection_state.dart';
import 'queued_action.dart';

/// Callback for receiving streamed response chunks from the hub.
typedef OnChunkReceived = void Function(String chunk);

/// Callback for receiving friendship state updates from the hub.
typedef OnFriendshipUpdate = void Function(Map<String, dynamic> data);

/// Callback for receiving the completion signal of a streamed response.
typedef OnStreamCompleted = void Function();

/// Data delivered when a streamed response is completed.
class StreamCompletedData {
  /// The full assembled response text.
  final String fullResponse;

  /// The detected emotion for the response.
  final String emotion;

  const StreamCompletedData({
    required this.fullResponse,
    required this.emotion,
  });
}

/// Configuration for the SignalR client reconnection behavior.
class SignalRClientConfig {
  /// The base URL of the SignalR hub (e.g., "https://api.momo.app/chatHub").
  final String hubUrl;

  /// Token provider for authentication with the hub.
  final Future<String> Function()? accessTokenFactory;

  /// Initial delay before first reconnection attempt (default: 1 second).
  final Duration initialRetryDelay;

  /// Maximum delay between reconnection attempts (default: 30 seconds).
  final Duration maxRetryDelay;

  /// Maximum number of reconnection attempts before giving up (default: 10).
  final int maxRetryAttempts;

  const SignalRClientConfig({
    required this.hubUrl,
    this.accessTokenFactory,
    this.initialRetryDelay = const Duration(seconds: 1),
    this.maxRetryDelay = const Duration(seconds: 30),
    this.maxRetryAttempts = 10,
  });
}

/// SignalR client with automatic reconnection and action queuing.
///
/// Provides real-time communication with the backend for:
/// - Streaming AI response chunks
/// - Receiving friendship state updates (XP, level-up, achievements)
/// - Queueing outbound actions during disconnection
///
/// Reconnection strategy:
/// - Exponential backoff starting at [SignalRClientConfig.initialRetryDelay]
/// - Doubles each attempt, capped at [SignalRClientConfig.maxRetryDelay]
/// - Maximum [SignalRClientConfig.maxRetryAttempts] attempts
/// - Displays failure indicator after all attempts exhausted
/// - Provides manual retry capability
///
/// Requirements: 9.3, 9.4, 9.5
class SignalRClient {
  final SignalRClientConfig _config;

  HubConnection? _hubConnection;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  bool _isDisposed = false;
  bool _isManualDisconnect = false;

  /// Queue of outbound actions collected while disconnected.
  final List<QueuedAction> _actionQueue = [];

  /// Stream controller for connection state changes.
  final StreamController<SignalRConnectionState> _connectionStateController =
      StreamController<SignalRConnectionState>.broadcast();

  /// Stream controller for incoming response chunks.
  final StreamController<String> _chunkController =
      StreamController<String>.broadcast();

  /// Stream controller for stream completion signals with full response data.
  final StreamController<StreamCompletedData> _streamCompletedController =
      StreamController<StreamCompletedData>.broadcast();

  /// Stream controller for friendship state updates.
  final StreamController<Map<String, dynamic>> _friendshipUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream controller for error messages from the hub.
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  SignalRConnectionState _currentState = SignalRConnectionState.disconnected;

  /// Creates a [SignalRClient] with the given configuration.
  // ignore: prefer_initializing_formals
  SignalRClient({required SignalRClientConfig config}) : _config = config;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Current connection state.
  SignalRConnectionState get connectionState => _currentState;

  /// Stream of connection state changes.
  ///
  /// UI can listen to this to show/hide connection indicators.
  Stream<SignalRConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream of incoming AI response chunks (real-time streaming).
  Stream<String> get chunkStream => _chunkController.stream;

  /// Stream emitting when a streamed response is complete, with full response data.
  Stream<StreamCompletedData> get streamCompletedStream =>
      _streamCompletedController.stream;

  /// Stream of friendship state updates (XP gain, level up, achievements).
  Stream<Map<String, dynamic>> get friendshipUpdateStream =>
      _friendshipUpdateController.stream;

  /// Stream of error messages received from the hub.
  Stream<String> get errorStream => _errorController.stream;

  /// Number of actions currently queued.
  int get queuedActionCount => _actionQueue.length;

  /// Whether the client is currently connected.
  bool get isConnected => _currentState == SignalRConnectionState.connected;

  /// Starts the SignalR connection.
  ///
  /// Builds the [HubConnection], registers hub method handlers,
  /// and initiates the connection. On failure, triggers reconnection.
  Future<void> connect() async {
    if (_isDisposed) return;
    _isManualDisconnect = false;

    _hubConnection = _buildConnection();
    _registerHubHandlers();
    _registerConnectionEvents();

    try {
      await _hubConnection!.start();
      _onConnected();
    } catch (_) {
      _onDisconnected();
    }
  }

  /// Disconnects from the hub gracefully.
  ///
  /// Cancels any pending retry timers and stops the connection.
  Future<void> disconnect() async {
    _isManualDisconnect = true;
    _cancelRetryTimer();
    _retryAttempt = 0;

    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (_) {
        // Ignore errors during intentional disconnect
      }
    }

    _updateState(SignalRConnectionState.disconnected);
  }

  /// Invokes a hub method on the server.
  ///
  /// If the connection is not active, the action is queued and will be
  /// delivered upon successful reconnection.
  ///
  /// [method] - The hub method name to invoke.
  /// [args] - Arguments to pass to the hub method.
  Future<void> invoke(String method, {List<Object>? args}) async {
    final arguments = args ?? [];

    if (_currentState == SignalRConnectionState.connected &&
        _hubConnection != null) {
      try {
        await _hubConnection!.invoke(method, args: arguments);
      } catch (_) {
        // If invocation fails, queue it for retry
        _enqueueAction(method, arguments);
      }
    } else {
      _enqueueAction(method, arguments);
    }
  }

  /// Manually triggers a reconnection attempt.
  ///
  /// Used when the user taps the "retry" button after all automatic
  /// reconnection attempts have been exhausted (state == failed).
  Future<void> manualRetry() async {
    if (_isDisposed) return;

    _retryAttempt = 0;
    _updateState(SignalRConnectionState.reconnecting);

    await _attemptReconnection();
  }

  /// Disposes all resources held by this client.
  ///
  /// After calling dispose, this client cannot be reused.
  void dispose() {
    _isDisposed = true;
    _cancelRetryTimer();
    _hubConnection?.stop();
    _connectionStateController.close();
    _chunkController.close();
    _streamCompletedController.close();
    _friendshipUpdateController.close();
    _errorController.close();
  }

  // ---------------------------------------------------------------------------
  // Reconnection Logic
  // ---------------------------------------------------------------------------

  /// Calculates the delay for the current retry attempt using exponential backoff.
  ///
  /// Formula: min(initialDelay * 2^attempt, maxDelay)
  /// Starting at 1s: 1, 2, 4, 8, 16, 30, 30, 30, 30, 30
  Duration calculateRetryDelay([int? attempt]) {
    final currentAttempt = attempt ?? _retryAttempt;
    final delayMs = _config.initialRetryDelay.inMilliseconds *
        pow(2, currentAttempt).toInt();
    final cappedMs = min(delayMs, _config.maxRetryDelay.inMilliseconds);
    return Duration(milliseconds: cappedMs);
  }

  /// Starts the reconnection cycle with exponential backoff.
  void _startReconnectionCycle() {
    if (_isDisposed || _isManualDisconnect) return;

    _updateState(SignalRConnectionState.reconnecting);
    _scheduleNextRetry();
  }

  /// Schedules the next reconnection attempt after the calculated delay.
  void _scheduleNextRetry() {
    if (_isDisposed || _isManualDisconnect) return;

    if (_retryAttempt >= _config.maxRetryAttempts) {
      // All attempts exhausted — signal failure for UI to show retry button
      _updateState(SignalRConnectionState.failed);
      return;
    }

    final delay = calculateRetryDelay();
    _retryTimer = Timer(delay, () => _attemptReconnection());
  }

  /// Attempts to reconnect to the hub.
  Future<void> _attemptReconnection() async {
    if (_isDisposed || _isManualDisconnect) return;

    _retryAttempt++;

    try {
      // Rebuild the connection for a fresh attempt
      _hubConnection = _buildConnection();
      _registerHubHandlers();
      _registerConnectionEvents();

      await _hubConnection!.start();
      _onConnected();
    } catch (_) {
      // Attempt failed, schedule next retry
      _scheduleNextRetry();
    }
  }

  // ---------------------------------------------------------------------------
  // Connection Event Handlers
  // ---------------------------------------------------------------------------

  void _registerConnectionEvents() {
    _hubConnection?.onclose(({Exception? error}) {
      if (!_isManualDisconnect && !_isDisposed) {
        _onDisconnected();
      }
    });
  }

  /// Called when connection is successfully established.
  void _onConnected() {
    _retryAttempt = 0;
    _cancelRetryTimer();
    _updateState(SignalRConnectionState.connected);

    // Deliver queued actions
    _flushActionQueue();
  }

  /// Called when connection is lost unexpectedly.
  void _onDisconnected() {
    if (_isManualDisconnect || _isDisposed) return;
    _startReconnectionCycle();
  }

  // ---------------------------------------------------------------------------
  // Hub Method Handlers
  // ---------------------------------------------------------------------------

  /// Registers handlers for incoming hub methods.
  ///
  /// Method names must match the backend IChatHubClient interface:
  /// - ReceiveResponseChunk: streaming AI response chunks
  /// - ReceiveResponseComplete: full response + emotion when stream ends
  /// - ReceiveFriendshipUpdate: XP, level-up, achievement notifications
  /// - ReceiveError: error messages from the hub
  void _registerHubHandlers() {
    // Streaming response chunks
    _hubConnection?.on('ReceiveResponseChunk', (List<Object?>? arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final chunk = arguments[0]?.toString() ?? '';
        if (chunk.isNotEmpty && !_chunkController.isClosed) {
          _chunkController.add(chunk);
        }
      }
    });

    // Stream completion signal with full response and emotion
    _hubConnection?.on('ReceiveResponseComplete', (List<Object?>? arguments) {
      if (!_streamCompletedController.isClosed) {
        final fullResponse =
            (arguments != null && arguments.isNotEmpty)
                ? arguments[0]?.toString() ?? ''
                : '';
        final emotion =
            (arguments != null && arguments.length > 1)
                ? arguments[1]?.toString() ?? ''
                : '';
        _streamCompletedController.add(StreamCompletedData(
          fullResponse: fullResponse,
          emotion: emotion,
        ));
      }
    });

    // Friendship state updates (XP gain, level up, achievement)
    _hubConnection?.on('ReceiveFriendshipUpdate', (List<Object?>? arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0];
        if (data is Map<String, dynamic> &&
            !_friendshipUpdateController.isClosed) {
          _friendshipUpdateController.add(data);
        }
      }
    });

    // Error messages from the hub
    _hubConnection?.on('ReceiveError', (List<Object?>? arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final errorMessage = arguments[0]?.toString() ?? 'Unknown error';
        if (!_errorController.isClosed) {
          _errorController.add(errorMessage);
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Action Queue
  // ---------------------------------------------------------------------------

  /// Enqueues an action to be delivered when connection is re-established.
  void _enqueueAction(String method, List<Object> args) {
    _actionQueue.add(QueuedAction(
      method: method,
      args: args,
      queuedAt: DateTime.now(),
    ));
  }

  /// Delivers all queued actions in order upon reconnection.
  Future<void> _flushActionQueue() async {
    if (_actionQueue.isEmpty) return;

    // Take a snapshot and clear the queue to avoid re-entrancy issues
    final actionsToDeliver = List<QueuedAction>.from(_actionQueue);
    _actionQueue.clear();

    for (int i = 0; i < actionsToDeliver.length; i++) {
      if (_currentState != SignalRConnectionState.connected) {
        // Connection lost again during flush — re-queue remaining actions
        _actionQueue.insertAll(0, actionsToDeliver.sublist(i));
        break;
      }

      try {
        final action = actionsToDeliver[i];
        await _hubConnection?.invoke(
          action.method,
          args: action.args.whereType<Object>().toList(),
        );
      } catch (_) {
        // Re-queue failed action and remaining ones
        _actionQueue.insertAll(0, actionsToDeliver.sublist(i));
        break;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  HubConnection _buildConnection() {
    final builder = HubConnectionBuilder().withUrl(
      _config.hubUrl,
      options: HttpConnectionOptions(
        accessTokenFactory: _config.accessTokenFactory,
      ),
    );

    // We handle reconnection ourselves with custom exponential backoff,
    // so we disable the library's built-in reconnection.
    return builder.build();
  }

  void _updateState(SignalRConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(newState);
      }
    }
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
