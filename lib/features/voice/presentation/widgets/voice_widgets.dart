/// Voice UI Widgets — animasi visualisasi suara untuk Momo
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/momo_design_system.dart';
import '../../domain/models/voice_models.dart';

// ===== MomoVoiceOrb =====

/// Orb beranimasi yang mencerminkan status voice session.
/// Saat listening: animasi pulse biru, saat Momo speaking: animasi ripple.
class MomoVoiceOrb extends StatefulWidget {
  final VoiceSessionMode mode;
  final VoiceConnectionState connectionState;
  final double audioLevel; // 0.0 - 1.0
  final double size;
  final VoidCallback? onTap;

  const MomoVoiceOrb({
    Key? key,
    required this.mode,
    required this.connectionState,
    this.audioLevel = 0.0,
    this.size = 120,
    this.onTap,
  }) : super(key: key);

  @override
  State<MomoVoiceOrb> createState() => _MomoVoiceOrbState();
}

class _MomoVoiceOrbState extends State<MomoVoiceOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _orbColor {
    return switch (widget.mode) {
      VoiceSessionMode.listening => MomoColors.primaryBlue,
      VoiceSessionMode.processing => const Color(0xFF9B59B6),
      VoiceSessionMode.speaking => const Color(0xFF27AE60),
      VoiceSessionMode.idle => MomoColors.textGrayLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.connectionState == VoiceConnectionState.connected;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = isActive
              ? _pulse.value + (widget.audioLevel * 0.15)
              : 1.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring glow (ripple effect saat aktif)
              if (isActive) ...[
                _buildRipple(scale: 1.0 + (widget.audioLevel * 0.3), opacity: 0.12),
                _buildRipple(scale: 1.15 + (widget.audioLevel * 0.2), opacity: 0.07),
                _buildRipple(scale: 1.3 + (widget.audioLevel * 0.15), opacity: 0.04),
              ],

              // Main orb
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _orbColor.withValues(alpha: 0.9),
                        _orbColor.withValues(alpha: 0.7),
                        _orbColor.withValues(alpha: 0.5),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _orbColor.withValues(alpha: isActive ? 0.5 : 0.2),
                        blurRadius: isActive ? 30 : 10,
                        spreadRadius: isActive ? 5 : 1,
                      ),
                    ],
                  ),
                  child: _OrbIcon(mode: widget.mode, connectionState: widget.connectionState),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRipple({required double scale, required double opacity}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _orbColor.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _OrbIcon extends StatelessWidget {
  final VoiceSessionMode mode;
  final VoiceConnectionState connectionState;
  const _OrbIcon({required this.mode, required this.connectionState});

  @override
  Widget build(BuildContext context) {
    if (connectionState == VoiceConnectionState.connecting) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    }

    final icon = switch (mode) {
      VoiceSessionMode.listening => Icons.mic_rounded,
      VoiceSessionMode.processing => Icons.memory_rounded,
      VoiceSessionMode.speaking => Icons.volume_up_rounded,
      VoiceSessionMode.idle => Icons.mic_none_rounded,
    };

    return Icon(icon, color: Colors.white, size: 36);
  }
}

// ===== AudioWaveform =====

/// Waveform bars yang beranimasi mengikuti audio level
class AudioWaveformBars extends StatefulWidget {
  final double audioLevel; // 0.0 - 1.0
  final Color color;
  final int barCount;
  final double height;

  const AudioWaveformBars({
    Key? key,
    required this.audioLevel,
    this.color = MomoColors.primaryBlue,
    this.barCount = 20,
    this.height = 48,
  }) : super(key: key);

  @override
  State<AudioWaveformBars> createState() => _AudioWaveformBarsState();
}

class _AudioWaveformBarsState extends State<AudioWaveformBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random(42);
  late List<double> _phases;

  @override
  void initState() {
    super.initState();
    _phases = List.generate(
      widget.barCount,
      (i) => _random.nextDouble() * 2 * pi,
    );
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final t = _controller.value * 2 * pi;
              final noise = sin(t + _phases[i]) * 0.5 + 0.5;
              final minHeight = widget.height * 0.1;
              final maxExtra = widget.height * 0.9;
              final barHeight = minHeight +
                  (maxExtra * widget.audioLevel * noise);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 3,
                  height: barHeight.clamp(minHeight, widget.height),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: 0.4 + (noise * widget.audioLevel * 0.6),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ===== VoiceStatusChip =====

/// Status chip kecil untuk AppBar/Home — "● Listening", "● Momo Speaking"
class VoiceStatusChip extends StatelessWidget {
  final VoiceSessionMode mode;
  final VoiceConnectionState connectionState;

  const VoiceStatusChip({
    Key? key,
    required this.mode,
    required this.connectionState,
  }) : super(key: key);

  Color get _color {
    return switch (mode) {
      VoiceSessionMode.listening => MomoColors.primaryBlue,
      VoiceSessionMode.processing => const Color(0xFF9B59B6),
      VoiceSessionMode.speaking => const Color(0xFF27AE60),
      VoiceSessionMode.idle => MomoColors.textGrayLight,
    };
  }

  String get _label {
    if (connectionState == VoiceConnectionState.connecting) return 'Menghubungkan...';
    if (connectionState == VoiceConnectionState.reconnecting) return 'Reconnecting...';
    return switch (mode) {
      VoiceSessionMode.listening => 'Mendengarkan...',
      VoiceSessionMode.processing => 'Momo berpikir...',
      VoiceSessionMode.speaking => 'Momo berbicara...',
      VoiceSessionMode.idle => 'Voice tersambung',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MomoRadius.full),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: _color),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (ctx, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _controller.value * 0.5),
        ),
      ),
    );
  }
}

// ===== VoiceSessionPanel =====

/// Panel voice session yang muncul di atas konten Home ketika voice aktif
class VoiceSessionPanel extends StatelessWidget {
  final VoiceSessionMode mode;
  final VoiceConnectionState connectionState;
  final double audioLevel;
  final bool isMicEnabled;
  final bool isSpeakerEnabled;
  final VoidCallback onMicToggle;
  final VoidCallback onSpeakerToggle;
  final VoidCallback onEndSession;

  const VoiceSessionPanel({
    Key? key,
    required this.mode,
    required this.connectionState,
    required this.audioLevel,
    required this.isMicEnabled,
    required this.isSpeakerEnabled,
    required this.onMicToggle,
    required this.onSpeakerToggle,
    required this.onEndSession,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: MomoSpacing.lg, vertical: MomoSpacing.sm),
      padding: const EdgeInsets.all(MomoSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(MomoRadius.xl),
        border: Border.all(
          color: MomoColors.primaryBlue.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: MomoColors.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status
          VoiceStatusChip(mode: mode, connectionState: connectionState),

          const SizedBox(height: MomoSpacing.lg),

          // Waveform
          AudioWaveformBars(
            audioLevel: audioLevel,
            color: MomoColors.primaryBlue,
            barCount: 24,
            height: 40,
          ),

          const SizedBox(height: MomoSpacing.lg),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mute mic
              _PanelButton(
                icon: isMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                label: isMicEnabled ? 'Mic On' : 'Mic Off',
                onTap: onMicToggle,
                isActive: !isMicEnabled,
                activeColor: MomoColors.error,
              ),

              // End session
              _PanelButton(
                icon: Icons.call_end_rounded,
                label: 'Tutup',
                onTap: onEndSession,
                isActive: true,
                activeColor: MomoColors.error,
                size: 52,
              ),

              // Speaker
              _PanelButton(
                icon: isSpeakerEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: isSpeakerEnabled ? 'Suara On' : 'Suara Off',
                onTap: onSpeakerToggle,
                isActive: !isSpeakerEnabled,
                activeColor: MomoColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;
  final double size;

  const _PanelButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
    required this.activeColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor.withValues(alpha: 0.12)
                  : MomoColors.primaryBlue.withValues(alpha: 0.1),
              border: Border.all(
                color: isActive
                    ? activeColor.withValues(alpha: 0.4)
                    : MomoColors.primaryBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : MomoColors.primaryBlue,
              size: size * 0.45,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? activeColor : MomoColors.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
