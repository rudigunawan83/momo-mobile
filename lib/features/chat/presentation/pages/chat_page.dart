import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../../core/theme/momo_design_system.dart';
import '../../../../core/models/base_models.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../../../providers.dart';
import '../../../voice/presentation/providers/voice_providers.dart';
import '../../../voice/presentation/widgets/voice_widgets.dart';
import '../../../voice/domain/models/voice_models.dart';

/// Full Chat Page — menampilkan conversation dengan Momo
/// Supports SSE streaming, optimistic UI, dan error recovery
class ChatPage extends ConsumerStatefulWidget {
  final String? conversationId;

  const ChatPage({Key? key, this.conversationId}) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Load conversation jika ada conversationId
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConversation();
    });
  }

  Future<void> _initConversation() async {
    final notifier = ref.read(chatNotifierProvider.notifier);
    if (widget.conversationId != null) {
      notifier.setConversationId(widget.conversationId!);
      await notifier.loadConversation(widget.conversationId!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(maxScroll);
    }
  }

  Future<void> _handleSendMessage(String text) async {
    final notifier = ref.read(chatNotifierProvider.notifier);
    final conversationId = ref.read(chatNotifierProvider).conversationId;

    // Jika belum ada conversation, buat dulu
    if (conversationId == null) {
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.createConversation();
      result.map(
        (conversation) {
          notifier.setConversationId(conversation.id);
        },
        (failure) {
          _showErrorSnackBar(
              'Gagal membuat percakapan. Coba lagi ya.');
          return;
        },
      );
    }

    // Scroll to bottom setelah user message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    await notifier.sendMessage(text);

    // Scroll to bottom setelah response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MomoColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MomoRadius.md),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final messages = chatState.messages;
    final pageState = chatState.pageState;
    final streamingContent = chatState.streamingContent;
    final isLoading = pageState is ChatLoading;
    final isStreaming = pageState is ChatStreaming;

    // Auto-scroll saat streaming
    ref.listen<String>(chatStreamingContentProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: false);
      });
    });

    return Scaffold(
      backgroundColor: MomoColors.backgroundLight,
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // AppBar
                _ChatAppBar(
                  momoStatus: isStreaming
                      ? 'speaking'
                      : isLoading
                          ? 'thinking'
                          : 'online',
                  glowController: _glowController,
                  isVoiceActive: ref.watch(isVoiceActiveProvider),
                  voiceMode: ref.watch(voiceSessionModeProvider),
                  voiceConnectionState: ref.watch(voiceConnectionStateProvider),
                ),

                // Messages
                Expanded(
                  child: _MessageListView(
                    messages: messages,
                    scrollController: _scrollController,
                    isLoading: isLoading,
                    isStreaming: isStreaming,
                    streamingContent: streamingContent,
                    pageState: pageState,
                    onRetry: () => ref.read(chatNotifierProvider.notifier).clearError(),
                  ),
                ),

                // Error banner jika ada
                if (pageState is ChatError)
                  _ErrorBanner(
                    message: (pageState).message,
                    onRetry: () =>
                        ref.read(chatNotifierProvider.notifier).clearError(),
                  ),

                // Chat input
                Padding(
                  padding: const EdgeInsets.all(MomoSpacing.lg),
                  child: ChatInputBar(
                    isLoading: isLoading || isStreaming,
                    onSend: _handleSendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F4FF),
              Color(0xFFF7F5EF),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Chat AppBar =====

class _ChatAppBar extends StatelessWidget {
  final String momoStatus;
  final AnimationController glowController;
  final bool isVoiceActive;
  final VoiceSessionMode voiceMode;
  final VoiceConnectionState voiceConnectionState;

  const _ChatAppBar({
    required this.momoStatus,
    required this.glowController,
    this.isVoiceActive = false,
    this.voiceMode = VoiceSessionMode.idle,
    this.voiceConnectionState = VoiceConnectionState.disconnected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MomoSpacing.lg,
            vertical: MomoSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.7),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: MomoColors.textBlack,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: MomoSpacing.md),

              // Momo avatar + identity
              AnimatedBuilder(
                animation: glowController,
                builder: (context, child) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4FA3FF), Color(0xFF1683FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MomoColors.primaryBlue.withOpacity(
                          0.3 + (glowController.value * 0.2),
                        ),
                        blurRadius: 8 + (glowController.value * 4),
                        spreadRadius: glowController.value,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: MomoSpacing.md),

              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Momo',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: MomoColors.textBlack,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: MomoColors.primaryBlue,
                        ),
                      ],
                    ),
                    _StatusBadge(status: momoStatus),
                  ],
                ),
              ),

              // Voice status chip + Menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isVoiceActive)
                    VoiceStatusChip(
                      mode: voiceMode,
                      connectionState: voiceConnectionState,
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: MomoColors.textGray,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _dotColor {
    return switch (status) {
      'online' => MomoColors.online,
      'thinking' => MomoColors.thinking,
      'speaking' => MomoColors.speaking,
      'listening' => MomoColors.thinking,
      _ => MomoColors.offline,
    };
  }

  String get _label {
    return switch (status) {
      'online' => 'Online',
      'thinking' => 'Momo berpikir...',
      'speaking' => 'Momo berbicara...',
      'listening' => 'Mendengarkan...',
      _ => 'Offline',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _dotColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            color: _dotColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ===== Message List View =====

class _MessageListView extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final bool isLoading;
  final bool isStreaming;
  final String streamingContent;
  final ChatPageState pageState;
  final VoidCallback onRetry;

  const _MessageListView({
    required this.messages,
    required this.scrollController,
    required this.isLoading,
    required this.isStreaming,
    required this.streamingContent,
    required this.pageState,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !isLoading && !isStreaming) {
      return _EmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: MomoSpacing.lg),
      itemCount: messages.length +
          (isLoading ? 1 : 0) +
          (isStreaming && streamingContent.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // Real messages
        if (index < messages.length) {
          return MessageBubble(
            message: messages[index],
            showAvatar: messages[index].role == 'assistant',
          );
        }

        // Streaming bubble
        if (isStreaming && streamingContent.isNotEmpty) {
          return StreamingBubble(content: streamingContent);
        }

        // Loading (thinking) indicator
        if (isLoading) {
          return const MomoThinkingIndicator();
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ===== Empty State =====

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4FA3FF), Color(0xFF1683FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: MomoColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: MomoSpacing.xl),
          const Text(
            'Hai! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MomoColors.textBlack,
            ),
          ),
          const SizedBox(height: MomoSpacing.sm),
          const Text(
            'Mulai percakapan dengan Momo',
            style: TextStyle(
              fontSize: 15,
              color: MomoColors.textGray,
            ),
          ),
          const SizedBox(height: MomoSpacing.xs),
          const Text(
            'Ketik pesan di bawah ini',
            style: TextStyle(
              fontSize: 14,
              color: MomoColors.textGrayLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Error Banner =====

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.lg,
        vertical: MomoSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.lg,
        vertical: MomoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: MomoColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(MomoRadius.lg),
        border: Border.all(
          color: MomoColors.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: MomoColors.error.withOpacity(0.8),
            size: 18,
          ),
          const SizedBox(width: MomoSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: MomoColors.error.withOpacity(0.8),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: MomoColors.primaryBlue,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Coba lagi',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
