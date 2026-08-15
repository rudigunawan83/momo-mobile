/// Chat Use Cases
import '../repositories/chat_repository.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/base_models.dart';

// ===== SendMessageUseCase =====

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase({required this.repository});

  Stream<ChatStreamEvent> call({
    required String conversationId,
    required String message,
  }) {
    return repository.sendMessage(
      conversationId: conversationId,
      message: message,
    );
  }
}

// ===== CreateConversationUseCase =====

class CreateConversationUseCase {
  final ChatRepository repository;

  CreateConversationUseCase({required this.repository});

  Future<Result<Conversation>> call({String? title}) {
    return repository.createConversation(title: title);
  }
}

// ===== GetConversationUseCase =====

class GetConversationUseCase {
  final ChatRepository repository;

  GetConversationUseCase({required this.repository});

  Future<Result<List<ChatMessage>>> call({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) {
    return repository.getConversation(
      conversationId: conversationId,
      limit: limit,
      offset: offset,
    );
  }
}

// ===== GetConversationsUseCase =====

class GetConversationsUseCase {
  final ChatRepository repository;

  GetConversationsUseCase({required this.repository});

  Future<Result<List<Conversation>>> call({
    int limit = 20,
    int offset = 0,
  }) {
    return repository.getConversations(
      limit: limit,
      offset: offset,
    );
  }
}

// ===== DeleteConversationUseCase =====

class DeleteConversationUseCase {
  final ChatRepository repository;

  DeleteConversationUseCase({required this.repository});

  Future<Result<void>> call(String conversationId) {
    return repository.deleteConversation(conversationId);
  }
}
