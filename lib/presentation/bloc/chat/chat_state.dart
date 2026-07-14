import '../../../domain/repositories/i_chat_repository.dart';

/// Represents a single message displayed in the chat UI.
class ChatMessageUI {
  /// The role: 'user' or 'assistant'.
  final String role;

  /// The text content of the message.
  final String content;

  /// Whether this message is currently being streamed (partial content).
  final bool isStreaming;

  /// The detected emotion (assistant messages only).
  final String? emotion;

  /// When the message was created.
  final DateTime timestamp;

  const ChatMessageUI({
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.emotion,
    required this.timestamp,
  });

  /// Creates a copy with optional overrides.
  ChatMessageUI copyWith({
    String? role,
    String? content,
    bool? isStreaming,
    String? emotion,
    DateTime? timestamp,
  }) {
    return ChatMessageUI(
      role: role ?? this.role,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      emotion: emotion ?? this.emotion,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Creates a [ChatMessageUI] from a domain [ChatMessage].
  factory ChatMessageUI.fromDomain(ChatMessage message) {
    return ChatMessageUI(
      role: message.role,
      content: message.content,
      emotion: message.emotion,
      timestamp: message.createdAt,
    );
  }
}

/// Notification data for XP gain / level-up events.
class XPNotification {
  /// Amount of XP gained.
  final int xpGained;

  /// Whether the user leveled up.
  final bool leveledUp;

  /// New level (if leveled up).
  final int? newLevel;

  /// New achievements (if any).
  final List<String> newAchievements;

  /// When the notification was created.
  final DateTime timestamp;

  const XPNotification({
    required this.xpGained,
    required this.leveledUp,
    this.newLevel,
    this.newAchievements = const [],
    required this.timestamp,
  });
}

/// States for the Chat BLoC.
///
/// Represents the current chat screen state including messages,
/// streaming status, voice state, and notifications.
sealed class ChatState {
  /// The list of all messages in the conversation.
  List<ChatMessageUI> get messages;

  const ChatState();
}

/// Initial state before chat is loaded.
class ChatInitial extends ChatState {
  @override
  List<ChatMessageUI> get messages => const [];

  const ChatInitial();
}

/// Chat history is being loaded.
class ChatLoadingHistory extends ChatState {
  @override
  final List<ChatMessageUI> messages;

  const ChatLoadingHistory({this.messages = const []});
}

/// Chat is loaded and idle — ready for user input.
class ChatReady extends ChatState {
  @override
  final List<ChatMessageUI> messages;

  /// Pending XP notifications to display.
  final List<XPNotification> notifications;

  const ChatReady({
    required this.messages,
    this.notifications = const [],
  });
}

/// Momo is "thinking" — user message sent, waiting for response.
class ChatWaitingForResponse extends ChatState {
  @override
  final List<ChatMessageUI> messages;

  const ChatWaitingForResponse({required this.messages});
}

/// Momo is streaming a response in real-time.
class ChatStreamingResponse extends ChatState {
  @override
  final List<ChatMessageUI> messages;

  /// The partial response text accumulated so far.
  final String partialResponse;

  const ChatStreamingResponse({
    required this.messages,
    required this.partialResponse,
  });
}

/// Voice recording is active (user holding mic button).
class ChatVoiceRecording extends ChatState {
  @override
  final List<ChatMessageUI> messages;

  /// Duration of the recording so far.
  final Duration recordingDuration;

  const ChatVoiceRecording({
    required this.messages,
    this.recordingDuration = Duration.zero,
  });
}

/// An error occurred during chat operations.
class ChatError extends ChatState {
  @override
  final List<ChatMessageUI> messages;

  /// Error description.
  final String errorMessage;

  const ChatError({
    required this.messages,
    required this.errorMessage,
  });
}
