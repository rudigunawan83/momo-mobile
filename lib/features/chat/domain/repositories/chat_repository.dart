/// Repository abstraction untuk Chat feature
import '../../../../core/errors/result.dart';
import '../../../../core/models/base_models.dart';

abstract class ChatRepository {
  /// Send message dengan streaming support
  /// 
  /// [conversationId] - ID dari conversation
  /// [message] - Message content
  /// [stream] - Jika true, return streaming response
  /// 
  /// Returns Stream<ChatStreamEvent> untuk streaming response
  /// Throws NetworkException, TimeoutException, UnauthorizedException
  Stream<ChatStreamEvent> sendMessage({
    required String conversationId,
    required String message,
    bool stream = true,
  });

  /// Get conversation history
  /// 
  /// [conversationId] - ID dari conversation
  /// [limit] - Jumlah messages (default 50)
  /// [offset] - Untuk pagination
  Future<Result<List<ChatMessage>>> getConversation({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  });

  /// Create new conversation
  /// 
  /// [title] - Optional conversation title
  Future<Result<Conversation>> createConversation({
    String? title,
  });

  /// Get all conversations
  /// 
  /// [limit] - Jumlah conversations (default 20)
  /// [offset] - Untuk pagination
  Future<Result<List<Conversation>>> getConversations({
    int limit = 20,
    int offset = 0,
  });

  /// Delete conversation
  Future<Result<void>> deleteConversation(String conversationId);
}

/// Chat Stream Events
abstract class ChatStreamEvent {
  const ChatStreamEvent();
}

/// Message start event
class ChatMessageStart extends ChatStreamEvent {
  final String messageId;
  final String conversationId;

  const ChatMessageStart({
    required this.messageId,
    required this.conversationId,
  });
}

/// Token streaming event
class ChatToken extends ChatStreamEvent {
  final String text;

  const ChatToken(this.text);
}

/// Tool start event (jika AI menggunakan tools)
class ChatToolStart extends ChatStreamEvent {
  final String toolName;
  final Map<String, dynamic> input;

  const ChatToolStart({
    required this.toolName,
    required this.input,
  });
}

/// Tool result event
class ChatToolResult extends ChatStreamEvent {
  final String toolName;
  final dynamic result;

  const ChatToolResult({
    required this.toolName,
    required this.result,
  });
}

/// Message complete event
class ChatMessageComplete extends ChatStreamEvent {
  final String messageId;
  final String fullContent;
  final Map<String, dynamic>? metadata;

  const ChatMessageComplete({
    required this.messageId,
    required this.fullContent,
    this.metadata,
  });
}

/// Stream error event
class ChatStreamError extends ChatStreamEvent {
  final String message;
  final Exception exception;

  const ChatStreamError({
    required this.message,
    required this.exception,
  });
}
