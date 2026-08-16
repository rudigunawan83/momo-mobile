/// Chat Repository Implementation
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/models/base_models.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<ChatStreamEvent> sendMessage({
    required String conversationId,
    required String message,
    bool stream = true,
  }) {
    return remoteDataSource.sendMessage(
      conversationId: conversationId,
      message: message,
      stream: stream,
    );
  }

  @override
  Future<Result<List<ChatMessage>>> getConversation({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await remoteDataSource.getConversation(
        conversationId: conversationId,
        limit: limit,
        offset: offset,
      );

      final messages = (response['messages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];

      return Success(messages);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal mengambil conversation',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal mengambil conversation',
      );
    }
  }

  @override
  Future<Result<Conversation>> createConversation({String? title}) async {
    try {
      final response = await remoteDataSource.createConversation(title: title);
      final conversation = Conversation.fromJson(response);
      return Success(conversation);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal membuat conversation',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal membuat conversation',
      );
    }
  }

  @override
  Future<Result<List<Conversation>>> getConversations({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await remoteDataSource.getConversations(
        limit: limit,
        offset: offset,
      );

      final conversations = response
          .map((e) => Conversation.fromJson(e))
          .toList();

      return Success(conversations);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal mengambil conversations',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal mengambil conversations',
      );
    }
  }

  @override
  Future<Result<void>> deleteConversation(String conversationId) async {
    try {
      await remoteDataSource.deleteConversation(conversationId);
      return Success(null);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal delete conversation',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal delete conversation',
      );
    }
  }
}
