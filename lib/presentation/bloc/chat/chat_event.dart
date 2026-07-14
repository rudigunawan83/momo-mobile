/// Events for the Chat BLoC.
///
/// Represents user actions and real-time updates that drive
/// the chat conversation flow.
sealed class ChatEvent {
  const ChatEvent();
}

/// User sends a text message to Momo.
///
/// Triggers: thinking state → API call → emotion update → response display.
/// Requirements: 1.1
class ChatMessageSent extends ChatEvent {
  /// The user's text message content.
  final String message;

  const ChatMessageSent({required this.message});
}

/// User sends a voice message (hold-to-talk released).
///
/// Triggers: recording stop → transcription → AI pipeline → TTS playback.
/// Requirements: 2.1, 2.3
class VoiceMessageSent extends ChatEvent {
  const VoiceMessageSent();
}

/// Voice recording started (user pressed and holds mic button).
class VoiceRecordingStarted extends ChatEvent {
  const VoiceRecordingStarted();
}

/// Voice recording cancelled (user released too early or swiped away).
class VoiceRecordingCancelled extends ChatEvent {
  const VoiceRecordingCancelled();
}

/// A streaming response chunk was received from SignalR.
///
/// Requirements: 9.1
class StreamingChunkReceived extends ChatEvent {
  /// The text chunk received from the hub.
  final String chunk;

  const StreamingChunkReceived({required this.chunk});
}

/// The streaming response has completed.
///
/// Requirements: 9.1
class StreamingResponseCompleted extends ChatEvent {
  /// The full assembled response text.
  final String fullResponse;

  /// The detected emotion for the response.
  final String emotion;

  const StreamingResponseCompleted({
    required this.fullResponse,
    required this.emotion,
  });
}

/// A friendship state update was received from SignalR.
///
/// Requirements: 9.2
class FriendshipUpdateReceived extends ChatEvent {
  /// XP gained in this update.
  final int xpGained;

  /// Whether the user leveled up.
  final bool leveledUp;

  /// New level (if leveled up).
  final int? newLevel;

  /// New achievements unlocked (if any).
  final List<String> newAchievements;

  const FriendshipUpdateReceived({
    required this.xpGained,
    required this.leveledUp,
    this.newLevel,
    this.newAchievements = const [],
  });
}

/// Chat history loaded (initial load or pagination).
class ChatHistoryLoaded extends ChatEvent {
  const ChatHistoryLoaded();
}
