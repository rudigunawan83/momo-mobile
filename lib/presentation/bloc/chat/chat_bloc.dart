import 'dart:async';

import '../../../data/realtime/signalr_client.dart';
import '../../../domain/engines/i_character_engine.dart';
import '../../../domain/engines/i_emotion_engine.dart';
import '../../../domain/entities/character_state.dart';
import '../../../domain/repositories/i_chat_repository.dart';
import '../../../domain/services/voice_service.dart';
import '../../../domain/services/voice_state.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC managing the chat conversation screen.
///
/// Orchestrates the flow between:
/// - User input (text/voice) → Character Engine (thinking) → API → Response
/// - SignalR streaming chunks → progressive response display
/// - SignalR friendship updates → XP/level-up notifications
/// - Response sentiment → Emotion Engine → Character Engine animation
///
/// Requirements: 1.1, 2.1, 2.3, 9.1, 9.2
class ChatBloc {
  final IChatRepository _chatRepository;
  final ICharacterEngine _characterEngine;
  final IEmotionEngine _emotionEngine;
  final SignalRClient _signalRClient;
  final VoiceService _voiceService;

  ChatState _currentState = const ChatInitial();
  bool _disposed = false;

  /// Buffer for accumulating streaming chunks.
  final StringBuffer _streamBuffer = StringBuffer();

  /// Pending XP notifications.
  final List<XPNotification> _pendingNotifications = [];

  // --- Subscriptions ---
  StreamSubscription<String>? _chunkSubscription;
  StreamSubscription<StreamCompletedData>? _streamCompletedSubscription;
  StreamSubscription<Map<String, dynamic>>? _friendshipUpdateSubscription;
  StreamSubscription<VoiceState>? _voiceStateSubscription;

  // --- Stream ---
  final StreamController<ChatState> _stateController =
      StreamController<ChatState>.broadcast();

  /// Creates a [ChatBloc] with required dependencies.
  ChatBloc({
    required IChatRepository chatRepository,
    required ICharacterEngine characterEngine,
    required IEmotionEngine emotionEngine,
    required SignalRClient signalRClient,
    required VoiceService voiceService,
  })  : _chatRepository = chatRepository,
        _characterEngine = characterEngine,
        _emotionEngine = emotionEngine,
        _signalRClient = signalRClient,
        _voiceService = voiceService {
    _subscribeToSignalR();
    _subscribeToVoiceState();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// The current state of the chat.
  ChatState get state => _currentState;

  /// Stream of state changes.
  Stream<ChatState> get stateStream => _stateController.stream;

  /// Dispatches an event to the BLoC.
  void add(ChatEvent event) {
    if (_disposed) return;

    switch (event) {
      case ChatMessageSent():
        _onMessageSent(event);
      case VoiceMessageSent():
        _onVoiceMessageSent();
      case VoiceRecordingStarted():
        _onVoiceRecordingStarted();
      case VoiceRecordingCancelled():
        _onVoiceRecordingCancelled();
      case StreamingChunkReceived():
        _onStreamingChunkReceived(event);
      case StreamingResponseCompleted():
        _onStreamingResponseCompleted(event);
      case FriendshipUpdateReceived():
        _onFriendshipUpdateReceived(event);
      case ChatHistoryLoaded():
        _onChatHistoryLoaded();
    }
  }

  // ---------------------------------------------------------------------------
  // Event Handlers
  // ---------------------------------------------------------------------------

  /// Handles sending a text message.
  ///
  /// Flow: add user message → set thinking state → send to API →
  /// wait for streaming response via SignalR.
  Future<void> _onMessageSent(ChatMessageSent event) async {
    final userMessage = ChatMessageUI(
      role: 'user',
      content: event.message,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [..._currentState.messages, userMessage];

    // Set character to thinking state
    _characterEngine.setState(CharacterState.thinking);
    _emit(ChatWaitingForResponse(messages: updatedMessages));

    // Clear the stream buffer for the incoming response
    _streamBuffer.clear();

    try {
      // Send message through repository (triggers backend processing)
      // The actual response will arrive via SignalR streaming
      final response = await _chatRepository.sendMessage(
        userId: '', // userId injected by repository implementation
        message: event.message,
      );

      // If we get a direct response (non-streaming fallback),
      // handle it as a complete response
      if (_currentState is ChatWaitingForResponse ||
          _currentState is ChatStreamingResponse) {
        _handleDirectResponse(response, updatedMessages);
      }
    } catch (e) {
      _characterEngine.setState(CharacterState.sad);
      _emit(ChatError(
        messages: updatedMessages,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handles a direct (non-streaming) response from the API.
  void _handleDirectResponse(
    ChatResponse response,
    List<ChatMessageUI> messagesBeforeResponse,
  ) {
    // Update emotion from response sentiment
    _updateEmotionFromResponse(response.emotion, response.sentimentScore);

    final assistantMessage = ChatMessageUI(
      role: 'assistant',
      content: response.message,
      emotion: response.emotion,
      timestamp: DateTime.now(),
    );

    final allMessages = [...messagesBeforeResponse, assistantMessage];

    // Create XP notification if XP was gained
    if (response.xpGained > 0) {
      _pendingNotifications.add(XPNotification(
        xpGained: response.xpGained,
        leveledUp: response.levelUp,
        timestamp: DateTime.now(),
      ));
    }

    _emit(ChatReady(
      messages: allMessages,
      notifications: List.from(_pendingNotifications),
    ));

    // Clear notifications after emitting (UI will pick them up)
    _pendingNotifications.clear();
  }

  /// Handles voice recording start (hold-to-talk).
  Future<void> _onVoiceRecordingStarted() async {
    try {
      await _voiceService.startRecording();
      _emit(ChatVoiceRecording(messages: _currentState.messages));
    } catch (e) {
      _emit(ChatError(
        messages: _currentState.messages,
        errorMessage: 'Failed to start recording: $e',
      ));
    }
  }

  /// Handles voice message sent (hold-to-talk released).
  ///
  /// Stops recording and lets VoiceService handle the flow:
  /// transcription → API → TTS → playback.
  Future<void> _onVoiceMessageSent() async {
    try {
      // Set character to thinking
      _characterEngine.setState(CharacterState.thinking);

      await _voiceService.stopRecording();

      // The VoiceService handles the entire voice pipeline.
      // We transition to waiting state; the voice state subscription
      // will update us when processing completes.
      _emit(ChatWaitingForResponse(messages: _currentState.messages));
    } catch (e) {
      _characterEngine.setState(CharacterState.sad);
      _emit(ChatError(
        messages: _currentState.messages,
        errorMessage: 'Voice processing failed: $e',
      ));
    }
  }

  /// Handles voice recording cancellation.
  Future<void> _onVoiceRecordingCancelled() async {
    await _voiceService.cancel();
    _emit(ChatReady(messages: _currentState.messages));
  }

  /// Handles a streaming response chunk from SignalR.
  ///
  /// Requirement 9.1: Each chunk delivered within 300ms.
  void _onStreamingChunkReceived(StreamingChunkReceived event) {
    _streamBuffer.write(event.chunk);
    final partialResponse = _streamBuffer.toString();

    // Build the message list with the partial streaming message
    final messages = List<ChatMessageUI>.from(_currentState.messages);

    // Remove previous streaming message if exists, then add updated one
    if (messages.isNotEmpty && messages.last.isStreaming) {
      messages.removeLast();
    }

    messages.add(ChatMessageUI(
      role: 'assistant',
      content: partialResponse,
      isStreaming: true,
      timestamp: DateTime.now(),
    ));

    _emit(ChatStreamingResponse(
      messages: messages,
      partialResponse: partialResponse,
    ));
  }

  /// Handles streaming response completion from SignalR.
  ///
  /// Requirement 9.1: Completion signal received after all chunks.
  void _onStreamingResponseCompleted(StreamingResponseCompleted event) {
    // Update emotion from the completed response
    _updateEmotionFromResponse(event.emotion, null);

    // Finalize the message list
    final messages = List<ChatMessageUI>.from(_currentState.messages);

    // Replace the streaming message with the final one
    if (messages.isNotEmpty && messages.last.isStreaming) {
      messages.removeLast();
    }

    messages.add(ChatMessageUI(
      role: 'assistant',
      content: event.fullResponse,
      isStreaming: false,
      emotion: event.emotion,
      timestamp: DateTime.now(),
    ));

    _streamBuffer.clear();

    _emit(ChatReady(
      messages: messages,
      notifications: List.from(_pendingNotifications),
    ));
    _pendingNotifications.clear();
  }

  /// Handles friendship update from SignalR.
  ///
  /// Requirement 9.2: Pushed within 500ms of event occurring.
  void _onFriendshipUpdateReceived(FriendshipUpdateReceived event) {
    final notification = XPNotification(
      xpGained: event.xpGained,
      leveledUp: event.leveledUp,
      newLevel: event.newLevel,
      newAchievements: event.newAchievements,
      timestamp: DateTime.now(),
    );

    _pendingNotifications.add(notification);

    // If we're in a ready state, emit immediately with notification
    if (_currentState is ChatReady) {
      _emit(ChatReady(
        messages: _currentState.messages,
        notifications: List.from(_pendingNotifications),
      ));
      _pendingNotifications.clear();
    }
    // Otherwise, notifications will be emitted with the next state transition
  }

  /// Loads chat history from the repository.
  Future<void> _onChatHistoryLoaded() async {
    _emit(ChatLoadingHistory(messages: _currentState.messages));

    try {
      final history = await _chatRepository.getHistory(
        userId: '', // userId injected by repository implementation
        page: 1,
        pageSize: 20,
      );

      final messages =
          history.map((m) => ChatMessageUI.fromDomain(m)).toList().reversed.toList();

      _emit(ChatReady(messages: messages));
    } catch (e) {
      _emit(ChatError(
        messages: _currentState.messages,
        errorMessage: 'Failed to load chat history: $e',
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // SignalR Subscriptions
  // ---------------------------------------------------------------------------

  /// Subscribes to SignalR streams for real-time updates.
  void _subscribeToSignalR() {
    // Subscribe to streaming chunks (Req 9.1)
    _chunkSubscription = _signalRClient.chunkStream.listen((chunk) {
      add(StreamingChunkReceived(chunk: chunk));
    });

    // Subscribe to stream completion (Req 9.1)
    _streamCompletedSubscription =
        _signalRClient.streamCompletedStream.listen((data) {
      add(StreamingResponseCompleted(
        fullResponse: data.fullResponse,
        emotion: data.emotion,
      ));
    });

    // Subscribe to friendship updates (Req 9.2)
    _friendshipUpdateSubscription =
        _signalRClient.friendshipUpdateStream.listen((data) {
      add(FriendshipUpdateReceived(
        xpGained: (data['xpGained'] as num?)?.toInt() ?? 0,
        leveledUp: data['leveledUp'] as bool? ?? false,
        newLevel: (data['newLevel'] as num?)?.toInt(),
        newAchievements:
            (data['newAchievements'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      ));
    });
  }

  /// Subscribes to VoiceService state changes to update chat state.
  void _subscribeToVoiceState() {
    _voiceStateSubscription = _voiceService.stateStream.listen((voiceState) {
      if (_disposed) return;

      switch (voiceState) {
        case VoiceState.idle:
          // Voice flow completed — return to ready state if we were in voice/waiting
          if (_currentState is ChatVoiceRecording ||
              _currentState is ChatWaitingForResponse) {
            _emit(ChatReady(messages: _currentState.messages));
          }
        case VoiceState.recording:
          _emit(ChatVoiceRecording(messages: _currentState.messages));
        case VoiceState.transcribing:
        case VoiceState.processing:
        case VoiceState.synthesizing:
        case VoiceState.playing:
          // Keep in waiting state during voice processing
          if (_currentState is! ChatWaitingForResponse) {
            _emit(ChatWaitingForResponse(messages: _currentState.messages));
          }
        case VoiceState.error:
          final error = _voiceService.lastError;
          // If TTS failed but response text is available, show it in chat
          if (error?.responseText != null) {
            final assistantMessage = ChatMessageUI(
              role: 'assistant',
              content: error!.responseText!,
              timestamp: DateTime.now(),
            );
            final messages = [
              ..._currentState.messages,
              assistantMessage,
            ];
            _emit(ChatReady(messages: messages));
          } else {
            _emit(ChatError(
              messages: _currentState.messages,
              errorMessage: error?.message ?? 'Voice error occurred',
            ));
          }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Emotion & Character Engine Wiring
  // ---------------------------------------------------------------------------

  /// Updates the Emotion Engine and Character Engine from a response's emotion.
  ///
  /// Wires: response sentiment → Emotion Engine → Character Engine animation.
  void _updateEmotionFromResponse(String emotion, double? sentimentScore) {
    // Update emotion engine from conversation
    final score = sentimentScore ?? _emotionStringToScore(emotion);
    _emotionEngine.updateFromConversation(ConversationEvent(
      sentimentScore: score,
      timestamp: DateTime.now(),
    ));

    // Map emotion string to character state
    final characterState = _emotionToCharacterState(emotion);
    _characterEngine.setState(characterState);
  }

  /// Maps an emotion string to a sentiment score for the Emotion Engine.
  double _emotionStringToScore(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 0.7;
      case 'excited':
        return 0.9;
      case 'curious':
        return 0.4;
      case 'neutral':
        return 0.0;
      case 'shy':
        return 0.2;
      case 'sad':
        return -0.5;
      case 'angry':
        return -0.7;
      case 'sleepy':
        return -0.1;
      default:
        return 0.0;
    }
  }

  /// Maps an emotion string to a [CharacterState].
  CharacterState _emotionToCharacterState(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return CharacterState.happy;
      case 'sad':
        return CharacterState.sad;
      case 'angry':
        return CharacterState.angry;
      case 'curious':
        return CharacterState.curious;
      case 'shy':
        return CharacterState.shy;
      case 'sleepy':
        return CharacterState.sleepy;
      case 'excited':
        return CharacterState.excited;
      case 'neutral':
      default:
        return CharacterState.neutral;
    }
  }

  // ---------------------------------------------------------------------------
  // State Management
  // ---------------------------------------------------------------------------

  void _emit(ChatState newState) {
    if (_disposed) return;
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Disposes all resources held by the BLoC.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _chunkSubscription?.cancel();
    _streamCompletedSubscription?.cancel();
    _friendshipUpdateSubscription?.cancel();
    _voiceStateSubscription?.cancel();
    _stateController.close();
  }
}
