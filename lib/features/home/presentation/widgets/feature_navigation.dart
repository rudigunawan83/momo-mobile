import 'package:flutter/material.dart';
import '../../../../core/theme/momo_design_system.dart';
import '../../../../core/widgets/momo_glass_widgets.dart';

/// Feature Navigation Bar - Chat, Misi, Mood, Musik
class MomoFeatureBar extends StatelessWidget {
  final String selectedFeature; // 'chat', 'mission', 'mood', 'music'
  final VoidCallback? onChatTap;
  final VoidCallback? onMissionTap;
  final VoidCallback? onMoodTap;
  final VoidCallback? onMusicTap;

  const MomoFeatureBar({
    Key? key,
    this.selectedFeature = 'mood',
    this.onChatTap,
    this.onMissionTap,
    this.onMoodTap,
    this.onMusicTap,
  }) : super(key: key);

  bool _isSelected(String feature) => selectedFeature == feature;

  @override
  Widget build(BuildContext context) {
    return MomoGlassCard(
      padding: const EdgeInsets.all(MomoSpacing.sm),
      borderRadius: MomoRadius.full,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _FeatureButton(
            icon: '💬',
            label: 'Chat',
            isSelected: _isSelected('chat'),
            onTap: onChatTap,
          ),
          _FeatureButton(
            icon: '◎',
            label: 'Misi',
            isSelected: _isSelected('mission'),
            onTap: onMissionTap,
          ),
          _FeatureButton(
            icon: '☺',
            label: 'Mood',
            isSelected: _isSelected('mood'),
            onTap: onMoodTap,
          ),
          _FeatureButton(
            icon: '♫',
            label: 'Musik',
            isSelected: _isSelected('music'),
            onTap: onMusicTap,
          ),
        ],
      ),
    );
  }
}

/// Feature Button - individual button dalam feature bar
class _FeatureButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MomoSpacing.md,
              vertical: MomoSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? MomoColors.primaryBlue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(MomoRadius.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: MomoSpacing.xs),
                Text(
                  label,
                  style: MomoTypography.labelSmall.copyWith(
                    color: isSelected
                        ? MomoColors.primaryBlue
                        : MomoColors.textGray,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Blue indicator dot
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(top: MomoSpacing.xs),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MomoColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Momo Chat Input - input field dengan send button
class MomoChatInput extends StatefulWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend;
  final Function(String)? onChanged;
  final String hintText;
  final VoidCallback? onVoicePressed;
  final bool isLoading;

  const MomoChatInput({
    Key? key,
    this.controller,
    this.onSend,
    this.onChanged,
    this.hintText = 'Ketik pesan...',
    this.onVoicePressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<MomoChatInput> createState() => _MomoChatInputState();
}

class _MomoChatInputState extends State<MomoChatInput> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateHasText);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_updateHasText);
    }
    super.dispose();
  }

  void _updateHasText() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _handleSend() {
    if (_hasText) {
      widget.onSend?.call();
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.lg,
        vertical: MomoSpacing.md,
      ),
      child: MomoGlassCard(
        borderRadius: MomoRadius.full,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // Text input
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                onSubmitted: (_) => _handleSend(),
                maxLines: 1,
                style: MomoTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: MomoTypography.bodyMedium.copyWith(
                    color: MomoColors.textGrayLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: MomoSpacing.lg,
                    vertical: MomoSpacing.lg,
                  ),
                ),
              ),
            ),
            // Send button
            Padding(
              padding: const EdgeInsets.only(right: MomoSpacing.md),
              child: GestureDetector(
                onTap: widget.isLoading ? null : _handleSend,
                child: AnimatedScale(
                  scale: _hasText && !widget.isLoading ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_upward,
                    color: _hasText && !widget.isLoading
                        ? MomoColors.primaryBlue
                        : MomoColors.textGrayLight,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
