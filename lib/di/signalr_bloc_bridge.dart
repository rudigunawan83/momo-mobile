import 'dart:async';

import '../data/realtime/connection_state.dart';
import '../data/realtime/signalr_client.dart';
import '../domain/engines/i_character_engine.dart';
import '../domain/engines/i_emotion_engine.dart';
import '../domain/entities/character_state.dart';
import '../domain/entities/emotion_state.dart';
import '../domain/entities/emotion_type.dart';
import '../domain/services/virtual_room/i_virtual_room_manager.dart';

/// Bridges real-time SignalR events to BLoC state updates and cross-engine wiring.
///
/// Responsibilities:
/// - Listens to SignalR friendship updates and updates [IVirtualRoomManager.friendshipLevel]
///   so that newly unlocked rooms become accessible (Req 8.3).
/// - Listens to [IEmotionEngine.emotionStream] and drives [ICharacterEngine.setState]
///   so that emotion changes are reflected visually (Req 3.1, 4.6).
/// - Exposes SignalR streams for BLoCs to consume (Req 9.1).
///
/// This class acts as the coordination layer between the real-time data source
/// (SignalR) and the presentation/domain engines, without coupling engines to
/// each other directly.
///
/// Requirements: 1.1, 3.1, 4.6, 7.1, 8.3, 9.1
class SignalRBlocBridge {
  final SignalRClient _signalRClient;
  final IEmotionEngine _emotionEngine;
  final ICharacterEngine _characterEngine;
  final IVirtualRoomManager _virtualRoomManager;

  StreamSubscription<Map<String, dynamic>>? _friendshipSubscription;
  StreamSubscription<EmotionState>? _emotionSubscription;
  StreamSubscription<StreamCompletedData>? _streamCompletedSubscription;

  bool _isStarted = false;

  /// Creates a [SignalRBlocBridge].
  ///
  /// All dependencies are injected for testability.
  SignalRBlocBridge({
    required SignalRClient signalRClient,
    required IEmotionEngine emotionEngine,
    required ICharacterEngine characterEngine,
    required IVirtualRoomManager virtualRoomManager,
  })  : _signalRClient = signalRClient,
        _emotionEngine = emotionEngine,
        _characterEngine = characterEngine,
        _virtualRoomManager = virtualRoomManager;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether the bridge is currently active and listening.
  bool get isStarted => _isStarted;

  /// The underlying SignalR client (for direct access to streams by BLoCs).
  SignalRClient get signalRClient => _signalRClient;

  /// Stream of incoming AI response chunks for real-time streaming display.
  ///
  /// BLoCs can listen to this for rendering streaming text (Req 9.1).
  Stream<String> get responseChunkStream => _signalRClient.chunkStream;

  /// Stream emitting when a streamed response is complete.
  ///
  /// Contains the full response text and detected emotion.
  Stream<StreamCompletedData> get responseCompletedStream =>
      _signalRClient.streamCompletedStream;

  /// Stream of friendship state updates from the backend.
  ///
  /// Contains level, XP, achievements data (Req 9.2).
  Stream<Map<String, dynamic>> get friendshipUpdateStream =>
      _signalRClient.friendshipUpdateStream;

  /// Stream of connection state changes for UI indicators.
  Stream<SignalRConnectionState> get connectionStateStream =>
      _signalRClient.connectionStateStream;

  /// Starts the bridge — connects SignalR and begins listening to all streams.
  ///
  /// Call this after authentication is confirmed during app initialization.
  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;

    // Connect SignalR
    await _signalRClient.connect();

    // Wire: Friendship updates → Virtual Room Manager (room unlocks)
    _friendshipSubscription =
        _signalRClient.friendshipUpdateStream.listen(_onFriendshipUpdate);

    // Wire: Emotion Engine output → Character Engine input
    _emotionSubscription =
        _emotionEngine.emotionStream.listen(_onEmotionChanged);

    // Wire: Stream completed → update Emotion Engine from response sentiment
    _streamCompletedSubscription =
        _signalRClient.streamCompletedStream.listen(_onStreamCompleted);
  }

  /// Stops the bridge — disconnects SignalR and cancels subscriptions.
  Future<void> stop() async {
    if (!_isStarted) return;
    _isStarted = false;

    await _friendshipSubscription?.cancel();
    _friendshipSubscription = null;

    await _emotionSubscription?.cancel();
    _emotionSubscription = null;

    await _streamCompletedSubscription?.cancel();
    _streamCompletedSubscription = null;

    await _signalRClient.disconnect();
  }

  /// Disposes all resources. Call during app teardown.
  void dispose() {
    _friendshipSubscription?.cancel();
    _emotionSubscription?.cancel();
    _streamCompletedSubscription?.cancel();
    _signalRClient.dispose();
  }

  // ---------------------------------------------------------------------------
  // Event Handlers
  // ---------------------------------------------------------------------------

  /// Handles friendship state updates from SignalR.
  ///
  /// Updates the Virtual Room Manager's friendship level so that newly
  /// unlocked rooms become accessible (Req 8.3, 7.1).
  void _onFriendshipUpdate(Map<String, dynamic> data) {
    final level = data['level'] as int?;
    if (level != null && level >= 1) {
      _virtualRoomManager.friendshipLevel = level;
    }
  }

  /// Handles emotion state changes from the Emotion Engine.
  ///
  /// Drives the Character Engine to transition smoothly to the new
  /// emotional state (Req 3.1, 4.6).
  void _onEmotionChanged(EmotionState emotionState) {
    // Map EmotionType to CharacterState
    final characterState = _emotionTypeToCharacterState(emotionState.primary);
    _characterEngine.setState(characterState);
  }

  /// Handles stream completion — triggers Emotion Engine update from
  /// the AI response emotion (Req 4.6).
  void _onStreamCompleted(StreamCompletedData data) {
    if (data.emotion.isEmpty) return;

    // Parse the emotion string and trigger a conversation event in the
    // Emotion Engine. The engine will calculate and emit the new state,
    // which then flows to Character Engine via _onEmotionChanged.
    final sentimentScore = _emotionToSentimentScore(data.emotion);
    _emotionEngine.updateFromConversation(
      ConversationEvent(
        sentimentScore: sentimentScore,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps an [EmotionType] to the corresponding [CharacterState].
  CharacterState _emotionTypeToCharacterState(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return CharacterState.happy;
      case EmotionType.sad:
        return CharacterState.sad;
      case EmotionType.angry:
        return CharacterState.angry;
      case EmotionType.curious:
        return CharacterState.curious;
      case EmotionType.shy:
        return CharacterState.shy;
      case EmotionType.sleepy:
        return CharacterState.sleepy;
      case EmotionType.neutral:
        return CharacterState.neutral;
      case EmotionType.excited:
        return CharacterState.excited;
    }
  }

  /// Converts an emotion string from the backend to a sentiment score.
  ///
  /// The backend returns emotion labels; we approximate a sentiment score
  /// for the Emotion Engine's conversation event processing.
  double _emotionToSentimentScore(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 0.7;
      case 'excited':
        return 0.9;
      case 'curious':
        return 0.3;
      case 'shy':
        return 0.1;
      case 'neutral':
        return 0.0;
      case 'sad':
        return -0.5;
      case 'angry':
        return -0.8;
      case 'sleepy':
        return -0.1;
      default:
        return 0.0;
    }
  }
}
