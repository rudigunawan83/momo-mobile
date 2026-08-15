import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/momo_design_system.dart';
import '../../../../core/models/base_models.dart';

// ===== MessageBubble =====

/// Chat message bubble — user (blue/right) atau assistant (glass/left)
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const MessageBubble({
    Key? key,
    required this.message,
    this.showAvatar = true,
  }) : super(key: key);

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60.0 : MomoSpacing.lg,
        right: isUser ? MomoSpacing.lg : 60.0,
        bottom: MomoSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && showAvatar) ...[
            _MomoAvatar(),
            const SizedBox(width: MomoSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                isUser ? _UserBubble(content: message.content) : _MomoBubble(content: message.content),
                const SizedBox(height: 4),
                _Timestamp(createdAt: message.createdAt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== StreamingBubble =====

/// Bubble khusus untuk menampilkan streaming response realtime
class StreamingBubble extends StatelessWidget {
  final String content;

  const StreamingBubble({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: MomoSpacing.lg,
        right: 60.0,
        bottom: MomoSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MomoAvatar(),
          const SizedBox(width: MomoSpacing.sm),
          Flexible(
            child: _MomoBubble(
              content: content,
              isStreaming: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== User Bubble =====

class _UserBubble extends StatelessWidget {
  final String content;
  const _UserBubble({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.lg,
        vertical: MomoSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1683FF),
            Color(0xFF0056CC),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(MomoRadius.xl),
          topRight: Radius.circular(MomoRadius.xl),
          bottomLeft: Radius.circular(MomoRadius.xl),
          bottomRight: Radius.circular(MomoRadius.sm),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1683FF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        content,
        style: MomoTypography.bodyMedium.copyWith(
          color: Colors.white,
          height: 1.5,
        ),
      ),
    );
  }
}

// ===== Momo Bubble =====

class _MomoBubble extends StatelessWidget {
  final String content;
  final bool isStreaming;

  const _MomoBubble({required this.content, this.isStreaming = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(MomoRadius.sm),
        topRight: Radius.circular(MomoRadius.xl),
        bottomLeft: Radius.circular(MomoRadius.xl),
        bottomRight: Radius.circular(MomoRadius.xl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MomoSpacing.lg,
            vertical: MomoSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(MomoRadius.sm),
              topRight: Radius.circular(MomoRadius.xl),
              bottomLeft: Radius.circular(MomoRadius.xl),
              bottomRight: Radius.circular(MomoRadius.xl),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  content,
                  style: MomoTypography.bodyMedium.copyWith(
                    color: MomoColors.textBlack,
                    height: 1.6,
                  ),
                ),
              ),
              if (isStreaming) ...[
                const SizedBox(width: 4),
                _StreamingCursor(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Streaming Cursor =====

class _StreamingCursor extends StatefulWidget {
  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: MomoColors.primaryBlue,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// ===== Momo Avatar =====

class _MomoAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'M',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ===== Timestamp =====

class _Timestamp extends StatelessWidget {
  final DateTime createdAt;
  const _Timestamp({required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return Text(
      '$hour:$minute',
      style: MomoTypography.labelSmall.copyWith(
        fontSize: 10,
        color: MomoColors.textGrayLight,
      ),
    );
  }
}
