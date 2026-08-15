/// Chat Providers — Riverpod state management untuk Chat feature
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../../../core/models/base_models.dart';
import '../../../providers.dart';

// ===== Use Case Providers =====

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(repository: ref.watch(chatRepositoryProvider));
});

final createConversationUseCaseProvider =
    Provider<CreateConversationUseCase>((ref) {
  return CreateConversationUseCase(
      repository: ref.watch(chatRepositoryProvider));
});

final getConversationUseCaseProvider =
    Provider<GetConversationUseCase>((ref) {
  return GetConversationUseCase(repository: ref.watch(chatRepositoryProvider));
});

final getConversationsUseCaseProvider =
    Provider<GetConversationsUseCase>((ref) {
  return GetConversationsUseCase(
      repository: ref.watch(chatRepositoryProvider));
});

// ===== Chat State =====

/// Sealed chat state
sealed class ChatPageState {
  const ChatPageState();
}

class ChatInitial extends ChatPageState {
  const ChatInitial();
}

class ChatLoading extends ChatPageState {
  const ChatLoading();
}

class ChatStreaming extends ChatPageState {
  final String streamingText;
  const ChatStreaming({required this.streamingText});
}

class ChatSuccess extends ChatPageState {
  const ChatSuccess();
}

class ChatError extends ChatPageState {
  final String message;
  const ChatError({required this.message});
}

// ===== ChatNotifier =====

/// State: messages list + streaming state + active conversation
class ChatNotifierState {
  final String? conversationId;
  final List<ChatMessage> messages;
  final ChatPageState pageState;
  final String streamingContent; // Accumulated streaming tokens

  const ChatNotifierState({
    this.conversationId,
    this.messages = const [],
    this.pageState = const ChatInitial(),
    this.streamingContent = '',
  });

  ChatNotifierState copyWith({
    String? conversationId,
    List<ChatMessage>? messages,
    ChatPageState? pageState,
    String? streamingContent,
  }) {
    return ChatNotifierState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      pageState: pageState ?? this.pageState,
      streamingContent: streamingContent ?? this.streamingContent,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatNotifierState> {
  final ChatRepository _repository;

  ChatNotifier({required ChatRepository repository})
      : _repository = repository,
        super(const ChatNotifierState());

  /// Load existing conversation
  Future<void> loadConversation(String conversationId) async {
    state = state.copyWith(
      conversationId: conversationId,
      pageState: const ChatLoading(),
    );

    final result = await _repository.getConversation(
      conversationId: conversationId,
    );

    result.map(
      (messages) {
        state = state.copyWith(
          messages: messages,
          pageState: const ChatSuccess(),
        );
      },
      (failure) {
        state = state.copyWith(
          pageState: ChatError(message: failure.message),
        );
      },
    );
  }

  /// Set conversation ID (setelah create baru)
  void setConversationId(String id) {
    state = state.copyWith(conversationId: id);
  }

  /// Send message dengan SSE streaming
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final conversationId = state.conversationId;
    if (conversationId == null) return;

    // Optimistic UI — tambah user message langsung
    final userMsg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      role: 'user',
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      pageState: const ChatLoading(),
      streamingContent: '',
    );

    // Buffer untuk accumulate streaming content
    String accumulated = '';

    // Streaming SSE events
    try {
      await for (final event in _repository.sendMessage(
        conversationId: conversationId,
        message: text.trim(),
      )) {
        if (event is ChatMessageStart) {
          // event.messageId captured — we use it on ChatMessageComplete
          state = state.copyWith(
            pageState: const ChatStreaming(streamingText: ''),
            streamingContent: '',
          );
        } else if (event is ChatToken) {
          accumulated += event.text;
          state = state.copyWith(
            pageState: ChatStreaming(streamingText: accumulated),
            streamingContent: accumulated,
          );
        } else if (event is ChatMessageComplete) {
          // Tambah assistant message ke list
          final assistantMsg = ChatMessage(
            id: event.messageId.isNotEmpty
                ? event.messageId
                : 'msg-${DateTime.now().millisecondsSinceEpoch}',
            conversationId: conversationId,
            role: 'assistant',
            content: event.fullContent.isNotEmpty ? event.fullContent : accumulated,
            createdAt: DateTime.now(),
            metadata: event.metadata,
          );

          state = state.copyWith(
            messages: [...state.messages, assistantMsg],
            pageState: const ChatSuccess(),
            streamingContent: '',
          );
          accumulated = '';
        } else if (event is ChatStreamError) {
          // Jika ada content yang sudah terstreaming, simpan
          if (accumulated.isNotEmpty) {
            final partialMsg = ChatMessage(
              id: 'partial-${DateTime.now().millisecondsSinceEpoch}',
              conversationId: conversationId,
              role: 'assistant',
              content: accumulated,
              createdAt: DateTime.now(),
            );
            state = state.copyWith(
              messages: [...state.messages, partialMsg],
            );
          }
          state = state.copyWith(
            pageState: const ChatError(
              message: 'Momo berhenti sebentar.\nCoba kirim ulang ya.',
            ),
            streamingContent: '',
          );
          break;
        }
      }
    } catch (e) {
      state = state.copyWith(
        pageState: const ChatError(
          message: 'Momo sedang mengalami sedikit gangguan.\nCoba lagi sebentar ya.',
        ),
        streamingContent: '',
      );
    }
  }

  /// Clear error state kembali ke success
  void clearError() {
    state = state.copyWith(pageState: const ChatSuccess());
  }

  /// Reset conversation
  void resetConversation() {
    state = const ChatNotifierState();
  }
}

/// ChatNotifier Provider
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatNotifierState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository: repository);
});

/// Convenience providers untuk easy access di UI
final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(chatNotifierProvider).messages;
});

final chatPageStateProvider = Provider<ChatPageState>((ref) {
  return ref.watch(chatNotifierProvider).pageState;
});

final chatStreamingContentProvider = Provider<String>((ref) {
  return ref.watch(chatNotifierProvider).streamingContent;
});

final isStreamingProvider = Provider<bool>((ref) {
  final pageState = ref.watch(chatPageStateProvider);
  return pageState is ChatStreaming;
});

final isChatLoadingProvider = Provider<bool>((ref) {
  final pageState = ref.watch(chatPageStateProvider);
  return pageState is ChatLoading;
});
