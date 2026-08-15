import 'package:flutter/material.dart';
import '../../../../core/theme/momo_design_system.dart';

/// Momo Robot - focal point utama
/// 
/// Menampilkan robot Momo dengan berbagai state animation:
/// - idle: floating up and down
/// - listening: glow meningkat
/// - thinking: glow berdenyut
/// - speaking: glow mengikuti audio level
class MomoRobot extends StatefulWidget {
  final String state; // idle, listening, thinking, speaking, happy, sad, offline
  final double size;
  final String? imagePath;
  final bool useAsset;

  const MomoRobot({
    Key? key,
    this.state = 'idle',
    this.size = 200,
    this.imagePath = 'assets/images/momo_robot.png',
    this.useAsset = false,
  }) : super(key: key);

  @override
  State<MomoRobot> createState() => _MomoRobotState();
}

class _MomoRobotState extends State<MomoRobot>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late Animation<Offset> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Float animation (naik turun)
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<Offset>(
      begin: const Offset(0, -10),
      end: const Offset(0, 10),
    ).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _updateGlowAnimation();
  }

  @override
  void didUpdateWidget(MomoRobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateGlowAnimation();
    }
  }

  void _updateGlowAnimation() {
    switch (widget.state.toLowerCase()) {
      case 'thinking':
      case 'speaking':
        if (!_glowController.isAnimating) {
          _glowController.repeat();
        }
        break;
      default:
        _glowController.stop();
        _glowController.reset();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color get _glowColor {
    switch (widget.state.toLowerCase()) {
      case 'offline':
        return MomoColors.offline;
      case 'thinking':
      case 'speaking':
        return MomoColors.momoGlow;
      case 'listening':
        return MomoColors.primaryBlueLight;
      case 'happy':
        return MomoColors.success;
      case 'sad':
        return MomoColors.error.withOpacity(0.5);
      default:
        return MomoColors.momoGlow;
    }
  }

  double get _glowSize {
    switch (widget.state.toLowerCase()) {
      case 'thinking':
      case 'speaking':
        return widget.size * 0.6;
      case 'listening':
        return widget.size * 0.5;
      default:
        return widget.size * 0.4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _floatAnimation.value,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          ScaleTransition(
            scale: widget.state == 'thinking' || widget.state == 'speaking'
                ? Tween<double>(begin: 0.8, end: 1.2).animate(
                    CurvedAnimation(
                      parent: _glowController,
                      curve: Curves.easeInOut,
                    ),
                  )
                : AlwaysStoppedAnimation(1.0),
            child: Container(
              width: _glowSize,
              height: _glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _glowColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: _glowColor.withOpacity(0.2),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Robot container
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: MomoShadows.mediumList,
              color: MomoColors.surfaceWhite,
              border: Border.all(
                color: _glowColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _buildRobotContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildRobotContent() {
    if (widget.useAsset && widget.imagePath != null) {
      return ClipOval(
        child: Image.asset(
          widget.imagePath!,
          fit: BoxFit.cover,
        ),
      );
    }

    // Placeholder/emoji robot
    return Center(
      child: Text(
        '🤖',
        style: TextStyle(
          fontSize: widget.size * 0.6,
        ),
      ),
    );
  }
}

/// Momo Robot dengan brightness adjustment untuk mood
class MomoRobotWithMood extends StatelessWidget {
  final String state;
  final String mood; // happy, sad, neutral, excited
  final double size;

  const MomoRobotWithMood({
    Key? key,
    this.state = 'idle',
    this.mood = 'neutral',
    this.size = 200,
  }) : super(key: key);

  double get _brightness {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return 1.1;
      case 'sad':
        return 0.8;
      default:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_getBrightnessMatrix(_brightness)),
      child: MomoRobot(
        state: state,
        size: size,
      ),
    );
  }

  List<double> _getBrightnessMatrix(double brightness) {
    final value = brightness;
    return [
      value, 0, 0, 0, 0,
      0, value, 0, 0, 0,
      0, 0, value, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
