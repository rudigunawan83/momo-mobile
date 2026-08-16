/// XP Progress Bar Widget — animated XP bar dengan level badge
import 'package:flutter/material.dart';
import '../../../../core/theme/momo_design_system.dart';

/// Animated XP progress bar yang menampilkan level saat ini,
/// XP saat ini, dan target XP ke level berikutnya.
class XpProgressBar extends StatefulWidget {
  final int currentXp;
  final int currentLevel;
  final int xpToNextLevel;
  final bool animate;

  const XpProgressBar({
    Key? key,
    required this.currentXp,
    required this.currentLevel,
    required this.xpToNextLevel,
    this.animate = true,
  }) : super(key: key);

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  double get _progressValue {
    if (widget.xpToNextLevel <= 0) return 1.0;
    return (widget.currentXp / widget.xpToNextLevel).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnim = Tween<double>(begin: 0, end: _progressValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXp != widget.currentXp) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: _progressValue,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level badge + XP numbers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MomoSpacing.md,
                vertical: MomoSpacing.xs,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(MomoRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    'Level ${widget.currentLevel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // XP numbers
            Text(
              '${widget.currentXp} / ${widget.xpToNextLevel} XP',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: MomoColors.textGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: MomoSpacing.sm),

        // Progress bar
        AnimatedBuilder(
          animation: _progressAnim,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(MomoRadius.pill),
              child: Stack(
                children: [
                  // Background
                  Container(
                    height: 10,
                    color: Colors.grey.withOpacity(0.15),
                  ),
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: _progressAnim.value,
                    child: Container(
                      height: 10,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                      ),
                    ),
                  ),
                  // Shimmer overlay
                  if (_progressAnim.value > 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
