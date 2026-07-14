import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/rive_fallback_handler.dart';

/// A widget that displays the Momo character using Rive animation when
/// available, and falls back to a static image when Rive is unavailable.
///
/// Uses [RiveFallbackHandler] to manage the transition between modes.
/// The transition between rive and static modes uses a cross-fade animation
/// for a smooth visual experience.
///
/// The [riveWidgetBuilder] callback produces the Rive widget when in rive mode.
/// The [staticImageBuilder] callback produces the static fallback widget.
class CharacterDisplayWidget extends StatefulWidget {
  /// The fallback handler that manages rive/static mode transitions.
  final RiveFallbackHandler fallbackHandler;

  /// Builder that produces the Rive animation widget.
  ///
  /// This will be called when [CharacterDisplayMode.rive] is active.
  /// The actual Rive widget integration will be wired later.
  final WidgetBuilder riveWidgetBuilder;

  /// Builder that produces the static character image fallback.
  ///
  /// This will be called when [CharacterDisplayMode.static] is active.
  final WidgetBuilder staticImageBuilder;

  /// Duration of the cross-fade animation between modes.
  final Duration transitionDuration;

  const CharacterDisplayWidget({
    super.key,
    required this.fallbackHandler,
    required this.riveWidgetBuilder,
    required this.staticImageBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  State<CharacterDisplayWidget> createState() => _CharacterDisplayWidgetState();
}

class _CharacterDisplayWidgetState extends State<CharacterDisplayWidget> {
  late CharacterDisplayMode _currentMode;
  StreamSubscription<CharacterDisplayMode>? _modeSubscription;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.fallbackHandler.currentMode;
    _modeSubscription = widget.fallbackHandler.modeStream.listen(_onModeChanged);
  }

  @override
  void didUpdateWidget(covariant CharacterDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fallbackHandler != widget.fallbackHandler) {
      _modeSubscription?.cancel();
      _currentMode = widget.fallbackHandler.currentMode;
      _modeSubscription =
          widget.fallbackHandler.modeStream.listen(_onModeChanged);
    }
  }

  @override
  void dispose() {
    _modeSubscription?.cancel();
    super.dispose();
  }

  void _onModeChanged(CharacterDisplayMode mode) {
    if (mounted) {
      setState(() {
        _currentMode = mode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: widget.transitionDuration,
      crossFadeState: _currentMode == CharacterDisplayMode.rive
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: widget.riveWidgetBuilder(context),
      secondChild: widget.staticImageBuilder(context),
    );
  }
}
