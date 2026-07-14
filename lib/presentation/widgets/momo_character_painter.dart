import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/entities/emotion_type.dart';

/// Configuration for Momo's expression based on current emotion.
class MomoExpression {
  /// The current emotion type driving the expression.
  final EmotionType emotion;

  /// Eye scale (1.0 = normal, 0.0 = closed/blink)
  final double eyeOpenness;

  /// Mouth curve (-1.0 = frown, 0.0 = neutral, 1.0 = big smile)
  final double mouthCurve;

  /// Mouth openness (0.0 = closed, 1.0 = wide open like laughing)
  final double mouthOpenness;

  /// Blush opacity (0.0 = none, 1.0 = full blush)
  final double blushIntensity;

  /// Jambul (tuft) angle in radians from center (-0.5 to 0.5)
  final double jambulAngle;

  /// Eye look direction offset (-1.0 = full left, 1.0 = full right)
  final double eyeLookX;

  /// Eye look direction offset (-1.0 = full up, 1.0 = full down)
  final double eyeLookY;

  /// Head tilt angle in radians
  final double headTilt;

  const MomoExpression({
    this.emotion = EmotionType.neutral,
    this.eyeOpenness = 1.0,
    this.mouthCurve = 0.3,
    this.mouthOpenness = 0.0,
    this.blushIntensity = 0.4,
    this.jambulAngle = 0.0,
    this.eyeLookX = 0.0,
    this.eyeLookY = 0.0,
    this.headTilt = 0.0,
  });

  /// Creates an expression from an [EmotionType].
  factory MomoExpression.fromEmotion(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return const MomoExpression(
          emotion: EmotionType.happy,
          eyeOpenness: 0.85,
          mouthCurve: 0.8,
          mouthOpenness: 0.1,
          blushIntensity: 0.7,
          jambulAngle: 0.1,
        );
      case EmotionType.excited:
        return const MomoExpression(
          emotion: EmotionType.excited,
          eyeOpenness: 1.0,
          mouthCurve: 1.0,
          mouthOpenness: 0.4,
          blushIntensity: 0.8,
          jambulAngle: 0.2,
        );
      case EmotionType.sad:
        return const MomoExpression(
          emotion: EmotionType.sad,
          eyeOpenness: 0.6,
          mouthCurve: -0.5,
          mouthOpenness: 0.0,
          blushIntensity: 0.2,
          jambulAngle: -0.15,
        );
      case EmotionType.angry:
        return const MomoExpression(
          emotion: EmotionType.angry,
          eyeOpenness: 0.7,
          mouthCurve: -0.3,
          mouthOpenness: 0.0,
          blushIntensity: 0.6,
          jambulAngle: 0.0,
        );
      case EmotionType.curious:
        return const MomoExpression(
          emotion: EmotionType.curious,
          eyeOpenness: 1.0,
          mouthCurve: 0.2,
          mouthOpenness: 0.15,
          blushIntensity: 0.3,
          jambulAngle: 0.1,
          headTilt: 0.15,
        );
      case EmotionType.shy:
        return const MomoExpression(
          emotion: EmotionType.shy,
          eyeOpenness: 0.5,
          mouthCurve: 0.3,
          mouthOpenness: 0.0,
          blushIntensity: 1.0,
          jambulAngle: -0.05,
          eyeLookY: 0.3,
        );
      case EmotionType.sleepy:
        return const MomoExpression(
          emotion: EmotionType.sleepy,
          eyeOpenness: 0.25,
          mouthCurve: 0.0,
          mouthOpenness: 0.2,
          blushIntensity: 0.2,
          jambulAngle: -0.2,
          headTilt: 0.1,
        );
      case EmotionType.neutral:
        return const MomoExpression(
          emotion: EmotionType.neutral,
          eyeOpenness: 1.0,
          mouthCurve: 0.3,
          mouthOpenness: 0.0,
          blushIntensity: 0.4,
          jambulAngle: 0.0,
        );
    }
  }
}

/// Static Momo character widget painted with Flutter CustomPaint.
///
/// Draws Momo's floating head with:
/// - Ivory white shell (kepala)
/// - Glossy black OLED face
/// - Big cyan eyes with glow
/// - Pink blush cheeks
/// - Expressive jambul (tuft)
/// - Cyan ear glow (cahaya ikonik)
/// - Dynamic mouth
///
/// This serves as the fallback when Rive animation is unavailable,
/// and also as a reference implementation of Momo's visual identity.
class MomoCharacterWidget extends StatefulWidget {
  /// The expression configuration for the character.
  final MomoExpression expression;

  /// Size of the character widget.
  final double size;

  /// Whether to show the ambient glow behind the character.
  final bool showGlow;

  const MomoCharacterWidget({
    super.key,
    this.expression = const MomoExpression(),
    this.size = 280,
    this.showGlow = true,
  });

  @override
  State<MomoCharacterWidget> createState() => _MomoCharacterWidgetState();
}

class _MomoCharacterWidgetState extends State<MomoCharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _MomoCharacterPainter(
              expression: widget.expression,
              glowIntensity: _glowAnimation.value,
              showGlow: widget.showGlow,
            ),
            size: Size(widget.size, widget.size),
          ),
        );
      },
    );
  }
}

/// CustomPainter that draws Momo's character based on the design reference.
class _MomoCharacterPainter extends CustomPainter {
  final MomoExpression expression;
  final double glowIntensity;
  final bool showGlow;

  // Momo's color palette (from design bible)
  static const Color shellColor = Color(0xFFF5F0E8); // Ivory White
  static const Color faceColor = Color(0xFF1A1A2E); // Glossy Black OLED
  static const Color eyeColor = Color(0xFF00E5FF); // Cyan
  static const Color blushColor = Color(0xFFFF8A9E); // Pink Blush
  static const Color mouthColor = Color(0xFF2D2D44); // Dark mouth
  static const Color earGlowColor = Color(0xFF00E5FF); // Cyan Glow

  _MomoCharacterPainter({
    required this.expression,
    required this.glowIntensity,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final headRadius = size.width * 0.38;

    // Apply head tilt
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(expression.headTilt);
    canvas.translate(-center.dx, -center.dy);

    // 1. Ambient glow (behind everything)
    if (showGlow) {
      _drawAmbientGlow(canvas, center, headRadius);
    }

    // 2. Shell (head shape - slightly egg-shaped, wider at bottom)
    _drawShell(canvas, center, headRadius);

    // 3. Face area (black glossy OLED)
    _drawFace(canvas, center, headRadius);

    // 4. Ear glows (cahaya ikonik)
    _drawEarGlows(canvas, center, headRadius);

    // 5. Eyes (big cyan with reflections)
    _drawEyes(canvas, center, headRadius);

    // 6. Mouth (dynamic, small but expressive)
    _drawMouth(canvas, center, headRadius);

    // 7. Blush (pipi merona)
    _drawBlush(canvas, center, headRadius);

    // 8. Jambul (expressive tuft on top)
    _drawJambul(canvas, center, headRadius);

    canvas.restore();
  }

  void _drawAmbientGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          eyeColor.withOpacity(0.15 * glowIntensity),
          eyeColor.withOpacity(0.05 * glowIntensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6));

    canvas.drawCircle(center, radius * 1.6, glowPaint);
  }

  void _drawShell(Canvas canvas, Offset center, double radius) {
    // Egg-shaped head - slightly taller than wide
    final headRect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 2.1,
    );

    // Shell gradient (ivory with subtle shading)
    final shellPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          shellColor,
          shellColor.withOpacity(0.95),
          const Color(0xFFE8E0D4),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(headRect);

    canvas.drawOval(headRect, shellPaint);

    // Subtle shell highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(headRect);

    canvas.drawOval(headRect, highlightPaint);
  }

  void _drawFace(Canvas canvas, Offset center, double radius) {
    // Face is the dark area - slightly smaller than shell, positioned center-lower
    final faceCenter = Offset(center.dx, center.dy + radius * 0.05);
    final faceRect = Rect.fromCenter(
      center: faceCenter,
      width: radius * 1.7,
      height: radius * 1.6,
    );

    final facePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        colors: [
          const Color(0xFF2A2A3E),
          faceColor,
          const Color(0xFF0D0D1A),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(faceRect);

    // Rounded rectangle for face area
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, Radius.circular(radius * 0.7)),
      facePaint,
    );
  }

  void _drawEarGlows(Canvas canvas, Offset center, double radius) {
    // Left ear glow
    final leftEarCenter = Offset(center.dx - radius * 0.85, center.dy - radius * 0.1);
    _drawSingleEarGlow(canvas, leftEarCenter, radius * 0.12);

    // Right ear glow
    final rightEarCenter = Offset(center.dx + radius * 0.85, center.dy - radius * 0.1);
    _drawSingleEarGlow(canvas, rightEarCenter, radius * 0.12);
  }

  void _drawSingleEarGlow(Canvas canvas, Offset center, double radius) {
    // Outer glow
    final outerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          earGlowColor.withOpacity(0.6 * glowIntensity),
          earGlowColor.withOpacity(0.2 * glowIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.5));

    canvas.drawCircle(center, radius * 2.5, outerGlowPaint);

    // Inner bright arc
    final arcPaint = Paint()
      ..color = earGlowColor.withOpacity(0.9 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.6,
      pi * 1.2,
      false,
      arcPaint,
    );
  }

  void _drawEyes(Canvas canvas, Offset center, double radius) {
    final eyeRadius = radius * 0.22;
    final eyeSpacing = radius * 0.38;
    final eyeY = center.dy - radius * 0.1;

    // Eye look offset
    final lookOffsetX = expression.eyeLookX * eyeRadius * 0.15;
    final lookOffsetY = expression.eyeLookY * eyeRadius * 0.1;

    // Left eye
    _drawSingleEye(
      canvas,
      Offset(center.dx - eyeSpacing + lookOffsetX, eyeY + lookOffsetY),
      eyeRadius,
    );

    // Right eye
    _drawSingleEye(
      canvas,
      Offset(center.dx + eyeSpacing + lookOffsetX, eyeY + lookOffsetY),
      eyeRadius,
    );
  }

  void _drawSingleEye(Canvas canvas, Offset center, double radius) {
    final openness = expression.eyeOpenness;

    // Eye height based on openness (for blink effect)
    final eyeHeight = radius * 2 * openness;
    if (eyeHeight < 2) {
      // Fully closed - draw a line
      final closedPaint = Paint()
        ..color = eyeColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(center.dx - radius * 0.7, center.dy),
        Offset(center.dx + radius * 0.7, center.dy),
        closedPaint,
      );
      return;
    }

    // Eye shape (oval based on openness)
    final eyeRect = Rect.fromCenter(
      center: center,
      width: radius * 1.8,
      height: eyeHeight,
    );

    // Eye glow (outer)
    final eyeGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          eyeColor.withOpacity(0.4 * glowIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.8));

    canvas.drawCircle(center, radius * 1.8, eyeGlowPaint);

    // Main eye color
    final eyePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        colors: [
          eyeColor,
          const Color(0xFF00B8D4),
          const Color(0xFF006D80),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(eyeRect);

    // Draw eye as oval
    canvas.drawOval(eyeRect, eyePaint);

    // Pupil (dark center)
    final pupilPaint = Paint()..color = const Color(0xFF001820);
    canvas.drawCircle(
      center,
      radius * 0.4 * openness,
      pupilPaint,
    );

    // Reflection (top-left highlight)
    final reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.85);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.3 * openness),
      radius * 0.2,
      reflectionPaint,
    );

    // Smaller secondary reflection
    final reflection2Paint = Paint()
      ..color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(
      Offset(center.dx + radius * 0.2, center.dy + radius * 0.15 * openness),
      radius * 0.08,
      reflection2Paint,
    );
  }

  void _drawMouth(Canvas canvas, Offset center, double radius) {
    final mouthCenter = Offset(center.dx, center.dy + radius * 0.4);
    final mouthWidth = radius * 0.25;
    final curve = expression.mouthCurve;
    final openness = expression.mouthOpenness;

    if (openness > 0.05) {
      // Open mouth (laughing/talking)
      final mouthRect = Rect.fromCenter(
        center: mouthCenter,
        width: mouthWidth * (1 + openness * 0.5),
        height: mouthWidth * openness * 0.8,
      );

      final mouthPaint = Paint()
        ..color = const Color(0xFF2D1520)
        ..style = PaintingStyle.fill;

      canvas.drawOval(mouthRect, mouthPaint);

      // Mouth outline
      final outlinePaint = Paint()
        ..color = mouthColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawOval(mouthRect, outlinePaint);
    } else {
      // Closed mouth - curved line
      final path = Path();
      path.moveTo(mouthCenter.dx - mouthWidth, mouthCenter.dy);
      path.quadraticBezierTo(
        mouthCenter.dx,
        mouthCenter.dy + mouthWidth * curve * 0.5,
        mouthCenter.dx + mouthWidth,
        mouthCenter.dy,
      );

      final mouthPaint = Paint()
        ..color = mouthColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, mouthPaint);
    }
  }

  void _drawBlush(Canvas canvas, Offset center, double radius) {
    final blushRadius = radius * 0.12;
    final blushY = center.dy + radius * 0.15;
    final blushSpacing = radius * 0.55;

    final blushPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          blushColor.withOpacity(expression.blushIntensity * 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(center.dx - blushSpacing, blushY),
        radius: blushRadius * 1.8,
      ));

    // Left blush
    canvas.drawCircle(
      Offset(center.dx - blushSpacing, blushY),
      blushRadius * 1.8,
      blushPaint,
    );

    // Right blush
    final rightBlushPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          blushColor.withOpacity(expression.blushIntensity * 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(center.dx + blushSpacing, blushY),
        radius: blushRadius * 1.8,
      ));

    canvas.drawCircle(
      Offset(center.dx + blushSpacing, blushY),
      blushRadius * 1.8,
      rightBlushPaint,
    );
  }

  void _drawJambul(Canvas canvas, Offset center, double radius) {
    // Jambul (expressive tuft) on top of head
    final jambulBase = Offset(center.dx, center.dy - radius * 1.0);
    final jambulAngle = expression.jambulAngle;

    final jambulPaint = Paint()
      ..color = shellColor
      ..style = PaintingStyle.fill;

    // Draw 3 tufts of varying sizes
    for (int i = 0; i < 3; i++) {
      final angle = jambulAngle + (i - 1) * 0.12;
      final height = radius * (0.25 - i * 0.05);
      final width = radius * (0.06 - i * 0.01);

      final path = Path();
      final tipX = jambulBase.dx + sin(angle) * height;
      final tipY = jambulBase.dy - cos(angle.abs()) * height;

      path.moveTo(jambulBase.dx - width, jambulBase.dy);
      path.quadraticBezierTo(tipX, tipY, jambulBase.dx + width, jambulBase.dy);
      path.close();

      canvas.drawPath(path, jambulPaint);
    }

    // Jambul highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final mainTipX = jambulBase.dx + sin(jambulAngle) * radius * 0.2;
    final mainTipY = jambulBase.dy - cos(jambulAngle.abs()) * radius * 0.2;

    canvas.drawLine(
      Offset(jambulBase.dx, jambulBase.dy - radius * 0.02),
      Offset(mainTipX, mainTipY),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MomoCharacterPainter oldDelegate) {
    return expression != oldDelegate.expression ||
        glowIntensity != oldDelegate.glowIntensity ||
        showGlow != oldDelegate.showGlow;
  }
}
