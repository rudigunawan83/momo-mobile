import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/momo_design_system.dart';
import '../../../../core/widgets/momo_glass_widgets.dart';

/// Voice Control Bar - 5 control buttons
class VoiceControlBar extends StatelessWidget {
  final VoidCallback? onMuteTap;
  final VoidCallback? onRecordTap;
  final VoidCallback? onMicrophoneTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onMusicTap;
  final bool isMuted;
  final bool isRecording;

  const VoiceControlBar({
    Key? key,
    this.onMuteTap,
    this.onRecordTap,
    this.onMicrophoneTap,
    this.onCameraTap,
    this.onMusicTap,
    this.isMuted = false,
    this.isRecording = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.lg,
        vertical: MomoSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute
          _VoiceControlButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            label: 'Mute',
            onTap: onMuteTap,
            isActive: isMuted,
          ),
          // Record
          _VoiceControlButton(
            icon: isRecording ? Icons.stop : Icons.radio_button_checked,
            label: 'Rekam',
            onTap: onRecordTap,
            isActive: isRecording,
          ),
          // Main Microphone (Large)
          GestureDetector(
            onTap: onMicrophoneTap,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: MomoShadows.glowList,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Backdrop filter
                    Container(
                      decoration: BoxDecoration(
                        color: MomoColors.primaryBlue.withOpacity(0.1),
                      ),
                    ),
                    // Icon
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MomoColors.surfaceWhite.withOpacity(0.9),
                        border: Border.all(
                          color: MomoColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: MomoColors.primaryBlue,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Camera
          _VoiceControlButton(
            icon: Icons.camera_alt,
            label: 'Kamera',
            onTap: onCameraTap,
          ),
          // Music
          _VoiceControlButton(
            icon: Icons.music_note,
            label: 'Musik',
            onTap: onMusicTap,
          ),
        ],
      ),
    );
  }
}

/// Voice Control Button - reusable button untuk voice controls
class _VoiceControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _VoiceControlButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MomoGlassButton(
            size: 48,
            onPressed: onTap ?? () {},
            isActive: isActive,
            child: Icon(
              icon,
              color: isActive ? MomoColors.primaryBlue : MomoColors.textBlack,
              size: 20,
            ),
          ),
          const SizedBox(height: MomoSpacing.xs),
          Text(
            label,
            style: MomoTypography.labelSmall.copyWith(
              fontSize: 10,
              color: isActive ? MomoColors.primaryBlue : MomoColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Main Microphone Button - tombol utama untuk voice input
class MainMicrophoneButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final String state; // idle, listening, processing, speaking
  final bool isActive;

  const MainMicrophoneButton({
    Key? key,
    this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.state = 'idle',
    this.isActive = false,
  }) : super(key: key);

  @override
  State<MainMicrophoneButton> createState() => _MainMicrophoneButtonState();
}

class _MainMicrophoneButtonState extends State<MainMicrophoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    if (widget.state == 'thinking' || widget.state == 'speaking') {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(MainMicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == 'thinking' || widget.state == 'speaking') {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _displayText {
    switch (widget.state.toLowerCase()) {
      case 'listening':
        return 'Mendengarkan...';
      case 'processing':
      case 'thinking':
        return 'Momo sedang berpikir...';
      case 'speaking':
        return 'Momo berbicara...';
      default:
        return 'Tahan untuk bicara';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing glow (hanya saat thinking/speaking)
        if (widget.state == 'thinking' || widget.state == 'speaking')
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.2).animate(
              CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: MomoColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: MomoSpacing.lg),
        // Main button
        GestureDetector(
          onTap: widget.onPressed,
          onLongPressStart: (_) => widget.onLongPressStart?.call(),
          onLongPressEnd: (_) => widget.onLongPressEnd?.call(),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: MomoShadows.glowList,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: MomoGlass.standardBlur,
                  sigmaY: MomoGlass.standardBlur,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? MomoColors.primaryBlue.withOpacity(0.2)
                        : MomoColors.surfaceWhite.withOpacity(0.9),
                    border: Border.all(
                      color: widget.isActive
                          ? MomoColors.primaryBlue
                          : MomoColors.primaryBlue.withOpacity(0.5),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      widget.state == 'speaking'
                          ? Icons.volume_up
                          : Icons.mic,
                      color: widget.isActive
                          ? MomoColors.primaryBlue
                          : MomoColors.textBlack,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: MomoSpacing.lg),
        Text(
          _displayText,
          style: MomoTypography.bodySmall.copyWith(
            color: MomoColors.textGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
