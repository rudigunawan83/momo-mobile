/// Interface for the Chat Repository.
///
/// Defines the contract for chat-related data operations,
/// bridging the domain layer to the data layer. Implementations
/// handle communication with the backend API via HTTP/SignalR.
abstract class IChatRepository {
  /// Sends a text message and returns the AI companion's response.
  ///
  /// [userId] - The authenticated user's identifier.
  /// [message] - The user's text message (max 4000 chars, non-empty).
  ///
  /// Returns a [ChatResponse] containing the AI reply, detected emotion,
  /// and any friendship XP gained.
  ///
  /// Throws if the message is empty, exceeds length limit, or the
  /// backend is unavailable.
  Future<ChatResponse> sendMessage({
    required String userId,
    required String message,
  });

  /// Sends a voice message (transcribed text) through the AI pipeline.
  ///
  /// [userId] - The authenticated user's identifier.
  /// [transcribedText] - Text from speech-to-text transcription.
  ///
  /// Returns a [ChatResponse] identical in structure to text messages.
  Future<ChatResponse> sendVoiceMessage({
    required String userId,
    required String transcribedText,
  });

  /// Retrieves paginated conversation history for a user.
  ///
  /// [userId] - The authenticated user's identifier.
  /// [page] - Page number (1-based).
  /// [pageSize] - Number of messages per page.
  ///
  /// Returns a list of [ChatMessage] ordered by most recent first.
  Future<List<ChatMessage>> getHistory({
    required String userId,
    int page = 1,
    int pageSize = 20,
  });
}

/// Represents a response from the AI chat pipeline.
class ChatResponse {
  /// The AI-generated response text.
  final String message;

  /// The detected emotion from the response.
  final String emotion;

  /// The sentiment score of the response, in `[-1.0, 1.0]`.
  final double sentimentScore;

  /// Amount of XP gained from this interaction.
  final int xpGained;

  /// Whether this interaction caused a level-up.
  final bool levelUp;

  const ChatResponse({
    required this.message,
    required this.emotion,
    required this.sentimentScore,
    required this.xpGained,
    required this.levelUp,
  });
}

/// Represents a single chat message in conversation history.
class ChatMessage {
  /// Unique message identifier.
  final String id;

  /// The user who owns this conversation.
  final String userId;

  /// Role of the message sender: 'user', 'assistant', or 'system'.
  final String role;

  /// The message text content.
  final String content;

  /// Type of the message: 'text', 'voice', or 'image'.
  final String type;

  /// The emotion detected in this message (assistant messages only).
  final String? emotion;

  /// When the message was created.
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.role,
    required this.content,
    required this.type,
    this.emotion,
    required this.createdAt,
  });
}
