import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/momo_design_system.dart';

/// Chat Input bar untuk ChatPage
/// Menggunakan same glass style seperti di Home
class ChatInputBar extends StatefulWidget {
  final bool isLoading;
  final Function(String) onSend;

  const ChatInputBar({
    Key? key,
    required this.onSend,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(MomoRadius.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MomoSpacing.lg,
            vertical: MomoSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(MomoRadius.full),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isLoading,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _handleSend(),
                  style: MomoTypography.bodyMedium.copyWith(
                    color: MomoColors.textBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.isLoading
                        ? 'Momo sedang berpikir...'
                        : 'Ketik pesan...',
                    hintStyle: MomoTypography.bodyMedium.copyWith(
                      color: MomoColors.textGrayLight,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: MomoSpacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: MomoSpacing.sm),
              _SendButton(
                isActive: _hasText && !widget.isLoading,
                isLoading: widget.isLoading,
                onTap: _handleSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _SendButton({
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1683FF), Color(0xFF0056CC)],
              )
            : null,
        color: isActive ? null : Colors.grey.withOpacity(0.15),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF1683FF).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isActive ? onTap : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.arrow_upward_rounded,
                    color: isActive ? Colors.white : MomoColors.textGrayLight,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
