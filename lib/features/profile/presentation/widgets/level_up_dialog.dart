/// Level Up Dialog — celebrasi ketika user naik level
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/momo_design_system.dart';

/// Dialog animasi yang muncul saat user naik level.
/// Tampilkan konfeti, level baru, dan XP yang didapat.
class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final int xpGained;
  final String? message;
  final VoidCallback? onContinue;

  const LevelUpDialog({
    Key? key,
    required this.newLevel,
    required this.xpGained,
    this.message,
    this.onContinue,
  }) : super(key: key);

  /// Show dialog helper
  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required int xpGained,
    String? message,
    VoidCallback? onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpDialog(
        newLevel: newLevel,
        xpGained: xpGained,
        message: message,
        onContinue: onContinue,
      ),
    );
  }

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _particles = List.generate(30, (_) => _ConfettiParticle());
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(MomoSpacing.xxl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MomoRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Confetti background
                AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                    child: const SizedBox(height: 0, width: double.infinity),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stars
                    const Text('🌟', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: MomoSpacing.md),

                    // Title
                    Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                      ),
                    ),
                    const SizedBox(height: MomoSpacing.sm),

                    // New level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MomoSpacing.xl,
                        vertical: MomoSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(MomoRadius.pill),
                      ),
                      child: Text(
                        'Level ${widget.newLevel}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: MomoSpacing.lg),

                    // XP gained
                    Container(
                      padding: const EdgeInsets.all(MomoSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(MomoRadius.lg),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: MomoSpacing.sm),
                          Text(
                            '+${widget.xpGained} XP',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB8860B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MomoSpacing.md),

                    // Message
                    Text(
                      widget.message ??
                          'Hubunganmu dengan Momo semakin kuat! 💜',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: MomoColors.textGray,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: MomoSpacing.xl),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onContinue?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: MomoSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MomoRadius.lg),
                          ),
                        ),
                        child: const Text(
                          'Lanjutkan! 🚀',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Confetti Particle System =====

class _ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double angle;

  static final _colors = [
    const Color(0xFF667EEA),
    const Color(0xFFFFD700),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF764BA2),
    const Color(0xFFFECE51),
  ];

  _ConfettiParticle()
      : x = Random().nextDouble(),
        y = Random().nextDouble() - 0.5,
        size = Random().nextDouble() * 6 + 4,
        color = _colors[Random().nextInt(_colors.length)],
        speed = Random().nextDouble() * 0.3 + 0.1,
        angle = Random().nextDouble() * pi * 2;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y + progress * p.speed) % 1.2;
      if (dy < 0) continue;

      final paint = Paint()..color = p.color.withOpacity(0.8);
      final cx = p.x * size.width;
      final cy = dy * size.height * 1.5 - size.height * 0.2;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(progress * pi * 2 * p.speed + p.angle);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
