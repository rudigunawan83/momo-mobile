import 'dart:async';

import 'package:flutter/material.dart';

import '../bloc/chat/chat_bloc.dart';
import '../bloc/chat/chat_event.dart';
import '../bloc/chat/chat_state.dart';

/// The main chat screen where users interact with Momo.
///
/// Design philosophy: 80% Robot, 20% UI — the character IS the UI.
/// The chat interface is minimal and unobtrusive, letting Momo's
/// character and animations take center stage.
///
/// Features:
/// - Message list with streaming response display (Req 9.1)
/// - Voice recording button with hold-to-talk (Req 2.1)
/// - XP gain and level-up notifications (Req 9.2)
/// - Real-time response streaming visualization
///
/// Requirements: 1.1, 2.1, 2.3, 9.1, 9.2
class ChatScreen extends StatefulWidget {
  /// The ChatBloc driving this screen's state.
  final ChatBloc chatBloc;

  const ChatScreen({
    super.key,
    required this.chatBloc,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();

  StreamSubscription<ChatState>? _stateSubscription;
  ChatState _currentState = const ChatInitial();

  /// Animation controller for XP notification pop-up.
  AnimationController? _xpAnimationController;
  Animation<double>? _xpAnimation;

  /// Currently displayed XP notification (if any).
  XPNotification? _activeNotification;

  @override
  void initState() {
    super.initState();
    _currentState = widget.chatBloc.state;
    _stateSubscription = widget.chatBloc.stateStream.listen(_onStateChanged);

    _xpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _xpAnimation = CurvedAnimation(
      parent: _xpAnimationController!,
      curve: Curves.elasticOut,
    );

    // Load chat history on init
    widget.chatBloc.add(const ChatHistoryLoaded());
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    _xpAnimationController?.dispose();
    super.dispose();
  }

  void _onStateChanged(ChatState state) {
    if (!mounted) return;
    setState(() {
      _currentState = state;
    });

    // Auto-scroll to bottom on new messages
    _scrollToBottom();

    // Show XP notification if present
    if (state is ChatReady && state.notifications.isNotEmpty) {
      _showXPNotification(state.notifications.last);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showXPNotification(XPNotification notification) {
    _activeNotification = notification;
    _xpAnimationController?.forward(from: 0.0);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _xpAnimationController?.reverse().then((_) {
          if (mounted) {
            setState(() {
              _activeNotification = null;
            });
          }
        });
      }
    });
  }

  void _onSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.chatBloc.add(ChatMessageSent(message: text));
    _textController.clear();
    _textFocusNode.requestFocus();
  }

  void _onVoiceRecordStart() {
    widget.chatBloc.add(const VoiceRecordingStarted());
  }

  void _onVoiceRecordEnd() {
    widget.chatBloc.add(const VoiceMessageSent());
  }

  void _onVoiceRecordCancel() {
    widget.chatBloc.add(const VoiceRecordingCancelled());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content: message list + input
            Column(
              children: [
                // Message list
                Expanded(child: _buildMessageList()),
                // Input area
                _buildInputArea(),
              ],
            ),
            // XP notification overlay
            if (_activeNotification != null) _buildXPNotification(),
            // Thinking indicator
            if (_currentState is ChatWaitingForResponse)
              _buildThinkingIndicator(),
          ],
        ),
      ),
    );
  }

  /// Builds the scrollable message list.
  Widget _buildMessageList() {
    final messages = _currentState.messages;

    if (messages.isEmpty && _currentState is ChatLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.cyanAccent,
          strokeWidth: 2,
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Ketuk untuk mulai ngobrol dengan Momo ✨',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// Builds a single message bubble.
  Widget _buildMessageBubble(ChatMessageUI message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.cyanAccent.withOpacity(0.15)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? Colors.cyanAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.cyanAccent : Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            // Streaming indicator
            if (message.isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildStreamingDots(),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the animated streaming dots indicator.
  Widget _buildStreamingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StreamingDot(delay: 0),
        const SizedBox(width: 3),
        _StreamingDot(delay: 200),
        const SizedBox(width: 3),
        _StreamingDot(delay: 400),
      ],
    );
  }

  /// Builds the input area with text field and voice button.
  Widget _buildInputArea() {
    final isRecording = _currentState is ChatVoiceRecording;
    final isWaiting = _currentState is ChatWaitingForResponse;
    final isStreaming = _currentState is ChatStreamingResponse;
    final isDisabled = isWaiting || isStreaming;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isRecording
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: isRecording
                  ? _buildRecordingIndicator()
                  : TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      enabled: !isDisabled,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _onSendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // Voice / Send button
          _buildActionButton(isDisabled: isDisabled, isRecording: isRecording),
        ],
      ),
    );
  }

  /// Builds the send/voice action button.
  ///
  /// Shows send icon when text is present, voice icon otherwise.
  /// Voice button uses hold-to-talk interaction (Req 2.1).
  Widget _buildActionButton({
    required bool isDisabled,
    required bool isRecording,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _textController,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;

        if (hasText) {
          // Send button
          return GestureDetector(
            onTap: isDisabled ? null : _onSendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.cyanAccent.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.cyanAccent.withOpacity(0.5),
                ),
              ),
              child: Icon(
                Icons.send_rounded,
                color: isDisabled
                    ? Colors.grey
                    : Colors.cyanAccent,
                size: 20,
              ),
            ),
          );
        }

        // Voice (mic) button — hold-to-talk
        return GestureDetector(
          onLongPressStart: isDisabled ? null : (_) => _onVoiceRecordStart(),
          onLongPressEnd: isDisabled ? null : (_) => _onVoiceRecordEnd(),
          onLongPressCancel: isDisabled ? null : _onVoiceRecordCancel,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isRecording
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecording
                    ? Colors.redAccent.withOpacity(0.6)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(
              isRecording ? Icons.mic : Icons.mic_none_rounded,
              color: isRecording ? Colors.redAccent : Colors.white70,
              size: 22,
            ),
          ),
        );
      },
    );
  }

  /// Builds the recording state indicator inside the text field area.
  Widget _buildRecordingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.mic, color: Colors.redAccent, size: 18),
          SizedBox(width: 8),
          Text(
            'Sedang merekam...',
            style: TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Builds the "thinking" indicator overlay.
  Widget _buildThinkingIndicator() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.cyanAccent.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.cyanAccent.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Momo sedang berpikir...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the XP gain / level-up notification overlay.
  Widget _buildXPNotification() {
    final notification = _activeNotification!;

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: ScaleTransition(
        scale: _xpAnimation!,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: notification.leveledUp
                  ? [
                      Colors.amber.withOpacity(0.9),
                      Colors.orange.withOpacity(0.9),
                    ]
                  : [
                      Colors.cyanAccent.withOpacity(0.8),
                      Colors.cyan.withOpacity(0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (notification.leveledUp ? Colors.amber : Colors.cyan)
                    .withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                notification.leveledUp ? Icons.star : Icons.add_circle_outline,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  notification.leveledUp
                      ? 'Level Up! Level ${notification.newLevel ?? ''} 🎉'
                      : '+${notification.xpGained} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (notification.newAchievements.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.emoji_events, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated dot for streaming response indicator.
class _StreamingDot extends StatefulWidget {
  final int delay;

  const _StreamingDot({required this.delay});

  @override
  State<_StreamingDot> createState() => _StreamingDotState();
}

class _StreamingDotState extends State<_StreamingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
