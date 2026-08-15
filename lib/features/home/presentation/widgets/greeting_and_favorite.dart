import 'package:flutter/material.dart';
import '../../../../core/theme/momo_design_system.dart';
import '../../../../core/widgets/momo_glass_widgets.dart';

/// Greeting Bubble - pesan sapaan dari Momo
class MomoGreetingBubble extends StatefulWidget {
  final String greeting;
  final String? emoji;
  final VoidCallback? onTap;

  const MomoGreetingBubble({
    Key? key,
    this.greeting = 'Hai Rudi! 👋\nSenang bertemu lagi!',
    this.emoji,
    this.onTap,
  }) : super(key: key);

  @override
  State<MomoGreetingBubble> createState() => _MomoGreetingBubbleState();
}

class _MomoGreetingBubbleState extends State<MomoGreetingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-20, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            child: MomoGlassCard(
              borderRadius: MomoRadius.xl,
              padding: const EdgeInsets.symmetric(
                horizontal: MomoSpacing.lg,
                vertical: MomoSpacing.md,
              ),
              child: Text(
                widget.greeting,
                style: MomoTypography.bodyLarge.copyWith(
                  color: MomoColors.textBlack,
                  height: 1.6,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Favorite Button - circular glass button
class FavoriteButton extends StatefulWidget {
  final bool isFavorited;
  final VoidCallback? onToggle;
  final double size;

  const FavoriteButton({
    Key? key,
    this.isFavorited = false,
    this.onToggle,
    this.size = 56,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isFavorited = !_isFavorited;
    });
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
      ),
      child: MomoGlassButton(
        size: widget.size,
        onPressed: _handleTap,
        isActive: _isFavorited,
        child: Text(
          _isFavorited ? '♥' : '♡',
          style: TextStyle(
            fontSize: widget.size * 0.4,
            color: _isFavorited ? MomoColors.error : MomoColors.textBlack,
          ),
        ),
      ),
    );
  }
}
