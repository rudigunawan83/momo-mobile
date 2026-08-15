import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/momo_design_system.dart';

/// MomoThinkingIndicator — animated ● ● ● dengan blue glow
/// Digunakan saat Momo sedang memproses atau berpikir
class MomoThinkingIndicator extends StatefulWidget {
  const MomoThinkingIndicator({Key? key}) : super(key: key);

  @override
  State<MomoThinkingIndicator> createState() => _MomoThinkingIndicatorState();
}

class _MomoThinkingIndicatorState extends State<MomoThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 3 dots dengan phase offset
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _dot1 = _buildDotAnimation(0.0);
    _dot2 = _buildDotAnimation(0.2);
    _dot3 = _buildDotAnimation(0.4);
  }

  Animation<double> _buildDotAnimation(double offset) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.3),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(offset, offset + 0.6, curve: Curves.linear),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          // Momo avatar
          _MomoMiniAvatar(),
          const SizedBox(width: MomoSpacing.sm),
          // Thinking bubble
          ClipRRect(
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
                  horizontal: MomoSpacing.xl,
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
                  children: [
                    _AnimatedDot(animation: _dot1),
                    const SizedBox(width: 5),
                    _AnimatedDot(animation: _dot2),
                    const SizedBox(width: 5),
                    _AnimatedDot(animation: _dot3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends AnimatedWidget {
  const _AnimatedDot({required Animation<double> animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Opacity(
      opacity: animation.value,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MomoColors.primaryBlue,
          boxShadow: [
            BoxShadow(
              color: MomoColors.primaryBlue.withOpacity(animation.value * 0.5),
              blurRadius: 4 * animation.value,
              spreadRadius: animation.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _MomoMiniAvatar extends StatelessWidget {
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
