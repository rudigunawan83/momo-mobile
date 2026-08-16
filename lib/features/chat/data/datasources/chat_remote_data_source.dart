/// Chat Remote Data Source dengan SSE streaming support
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/chat_repository.dart';

abstract class ChatRemoteDataSource {
  /// Send message dengan streaming support
  /// 
  /// Returns Stream<ChatStreamEvent> untuk real-time token streaming
  Stream<ChatStreamEvent> sendMessage({
    required String conversationId,
    required String message,
    bool stream = true,
  });

  /// Get conversation history
  Future<Map<String, dynamic>> getConversation({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  });

  /// Create new conversation
  Future<Map<String, dynamic>> createConversation({String? title});

  /// Get all conversations
  Future<List<Map<String, dynamic>>> getConversations({
    int limit = 20,
    int offset = 0,
  });

  /// Delete conversation
  Future<void> deleteConversation(String conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Stream<ChatStreamEvent> sendMessage({
    required String conversationId,
    required String message,
    bool stream = true,
  }) async* {
    try {
      // Emit message_start
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      yield ChatMessageStart(
        messageId: messageId,
        conversationId: conversationId,
      );

      // Call non-streaming /chat/message — more reliable than SSE on Android
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.chatMessage, // '/chat/message'
        data: {
          'conversationId': conversationId,
          'message': message,
          'conversationType': 'Text',
        },
        options: Options(
          // 40s — server has 30s AI timeout + processing overhead
          receiveTimeout: const Duration(seconds: 40),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final text = response['message'] as String? ??
          response['text'] as String? ??
          'Hmm, Momo lagi butuh istirahat sebentar. Coba lagi ya! 🤗';

      final emotion = response['emotion'] as String? ?? 'neutral';
      final xpGained = response['xpGained'] as int? ?? 0;
      final levelUp = response['levelUp'] as bool? ?? false;

      // Simulate word-by-word streaming client-side
      final words = text.split(' ');
      for (final word in words) {
        yield ChatToken('$word ');
        await Future.delayed(const Duration(milliseconds: 40));
      }

      // Emit complete
      yield ChatMessageComplete(
        messageId: messageId,
        fullContent: text,
        metadata: {
          'emotion': emotion,
          'xpGained': xpGained,
          'levelUp': levelUp,
        },
      );
    } on TimeoutException catch (e) {
      yield ChatStreamError(message: 'Koneksi timeout', exception: e);
    } on NetworkException catch (e) {
      yield ChatStreamError(message: 'Network error', exception: e);
    } on ServerException catch (e) {
      yield ChatStreamError(message: e.message, exception: e);
    } catch (e) {
      yield ChatStreamError(
        message: 'Terjadi kesalahan: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }


  ChatStreamEvent _parseEvent(String eventType, Map<String, dynamic> data) {
    switch (eventType) {
      case 'message_start':
        return ChatMessageStart(
          messageId: data['messageId'] as String? ?? '',
          conversationId: data['conversationId'] as String? ?? '',
        );
      
      case 'token':
        return ChatToken(data['text'] as String? ?? '');
      
      case 'tool_start':
        return ChatToolStart(
          toolName: data['toolName'] as String? ?? '',
          input: data['input'] as Map<String, dynamic>? ?? {},
        );
      
      case 'tool_result':
        return ChatToolResult(
          toolName: data['toolName'] as String? ?? '',
          result: data['result'],
        );

      // API kita emit 'message_end' — map ke message_complete
      case 'message_end':
        return ChatMessageComplete(
          messageId: data['messageId'] as String? ?? '',
          fullContent: '', // sudah terakumulasi dari token events
          metadata: {
            'emotion': data['emotion'],
            'xpGained': data['xpGained'],
            'levelUp': data['levelUp'],
            'newAchievements': data['newAchievements'],
          },
        );

      case 'message_complete':
        return ChatMessageComplete(
          messageId: data['messageId'] as String? ?? '',
          fullContent: data['content'] as String? ?? '',
          metadata: data['metadata'] as Map<String, dynamic>?,
        );

      case 'error':
        return ChatStreamError(
          message: data['message'] as String? ?? 'Unknown error',
          exception: Exception(data['code'] ?? data['error']),
        );

      default:
        // Skip unknown events secara diam-diam
        return ChatToken(''); // empty token — akan diabaikan oleh notifier
    }
  }

  @override
  Future<Map<String, dynamic>> getConversation({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '${ApiEndpoints.conversations}/$conversationId?limit=$limit&offset=$offset',
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createConversation({String? title}) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.conversations,
        data: {
          if (title != null) 'title': title,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getConversations({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        '${ApiEndpoints.conversations}?limit=$limit&offset=$offset',
      );
      return List<Map<String, dynamic>>.from(
        response.map((e) => e as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      await apiClient.delete('${ApiEndpoints.conversations}/$conversationId');
    } catch (e) {
      rethrow;
    }
  }
}
