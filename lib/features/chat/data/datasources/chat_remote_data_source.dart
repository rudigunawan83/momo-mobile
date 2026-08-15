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
      final dio = apiClient.dio;

      // Request body sesuai StreamMessageRequest di API
      final requestData = {
        'conversationId': conversationId,
        'message': message,
        // userId dikosongkan — server pakai dev fallback atau extract dari JWT
      };

      // POST ke /api/chat/stream — SSE endpoint
      final response = await dio.post(
        ApiEndpoints.chatStream, // '/chat/stream'
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to send message',
          statusCode: response.statusCode,
        );
      }

      // Parse SSE stream
      final sseStream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in sseStream) {
        buffer += utf8.decode(chunk);
        
        // Split by newlines untuk parse events
        final lines = buffer.split('\n');
        buffer = lines.last; // Keep incomplete line for next iteration

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          
          if (line.isEmpty) continue;

          // Parse event: ...
          if (line.startsWith('event:')) {
            final eventType = line.substring(6).trim();
            
            // Next line should be data: ...
            if (i + 1 < lines.length - 1) {
              final dataLine = lines[i + 1];
              if (dataLine.startsWith('data:')) {
                final jsonStr = dataLine.substring(5).trim();
                try {
                  final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
                  
                  // Parse different event types
                  yield _parseEvent(eventType, jsonData);
                  
                  i++; // Skip data line
                } catch (e) {
                  yield ChatStreamError(
                    message: 'Failed to parse event data',
                    exception: e as Exception,
                  );
                }
              }
            }
          }
        }
      }
    } on TimeoutException catch (e) {
      yield ChatStreamError(
        message: 'Stream timeout',
        exception: e,
      );
    } on NetworkException catch (e) {
      yield ChatStreamError(
        message: 'Network error',
        exception: e,
      );
    } catch (e) {
      yield ChatStreamError(
        message: 'Stream error: $e',
        exception: e as Exception,
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
