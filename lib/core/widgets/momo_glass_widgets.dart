import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/momo_design_system.dart';

/// Reusable Glassmorphism Card Widget
/// 
/// Membuat efek kaca frosted dengan blur backdrop.
/// Cocok untuk semua komponen glass pada desain.
class MomoGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final double borderRadius;
  final EdgeInsets padding;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const MomoGlassCard({
    Key? key,
    required this.child,
    this.blur = MomoGlass.standardBlur,
    this.opacity = MomoGlass.standardOpacity,
    this.borderOpacity = MomoGlass.standardBorderOpacity,
    this.borderRadius = MomoRadius.lg,
    this.padding = const EdgeInsets.all(MomoSpacing.md),
    this.border,
    this.boxShadow,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: (backgroundColor ?? MomoColors.surfaceWhite)
                .withOpacity(opacity),
            border: border ??
                Border.all(
                  color: MomoColors.textWhite
                      .withOpacity(borderOpacity),
                  width: 1.5,
                ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: boxShadow ?? MomoShadows.lightList,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Momo Glass Button - untuk tombol dengan efek glass
class MomoGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double size;
  final Color? glowColor;
  final bool isActive;

  const MomoGlassButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.size = 56,
    this.glowColor,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isActive
              ? MomoShadows.glowList
              : MomoShadows.lightList,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: MomoGlass.standardBlur,
              sigmaY: MomoGlass.standardBlur,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: MomoColors.surfaceWhite
                    .withOpacity(MomoGlass.standardOpacity),
                border: Border.all(
                  color: isActive
                      ? MomoColors.primaryBlue.withOpacity(0.5)
                      : MomoColors.textWhite
                          .withOpacity(MomoGlass.standardBorderOpacity),
                  width: isActive ? 2 : 1.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Momo Input Glass Field - untuk text input dengan efek glass
class MomoGlassInput extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final VoidCallback? onSubmitted;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;

  const MomoGlassInput({
    Key? key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
  }) : super(key: key);

  @override
  State<MomoGlassInput> createState() => _MomoGlassInputState();
}

class _MomoGlassInputState extends State<MomoGlassInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(MomoRadius.full),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: MomoGlass.standardBlur,
          sigmaY: MomoGlass.standardBlur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: MomoColors.surfaceWhite
                .withOpacity(MomoGlass.standardOpacity),
            border: Border.all(
              color: _isFocused
                  ? MomoColors.primaryBlue
                  : MomoColors.textWhite
                      .withOpacity(MomoGlass.standardBorderOpacity),
              width: _isFocused ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(MomoRadius.full),
            boxShadow: MomoShadows.lightList,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onSubmitted: (_) => widget.onSubmitted?.call(),
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            obscureText: widget.obscureText,
            style: MomoTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: MomoTypography.bodyMedium.copyWith(
                color: MomoColors.textGrayLight,
              ),
              border: InputBorder.none,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: MomoSpacing.lg,
                vertical: MomoSpacing.lg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
