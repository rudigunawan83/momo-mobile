import 'dart:async';
import 'dart:ui' show Offset;

import '../entities/character_state.dart';
import 'animation_type.dart';
import 'character_engine_error.dart';
import 'i_character_engine.dart';

/// Implementation of [ICharacterEngine] managing Momo's visual state machine.
///
/// This class handles:
/// - State transitions with 500ms interpolation
/// - Idle loop activation after 5 seconds of inactivity
/// - Eye-tracking target updates within 100ms
/// - State change and error event streams
///
/// The state machine is flat — all [CharacterState] values can transition
/// to any other state. Setting the same state as current is a no-op
/// (no error, no emission).
///
/// Rive integration is deferred to a later task; this implementation
/// focuses on the logic/state machine layer.
class CharacterEngine implements ICharacterEngine {
  /// Duration of the interpolation transition between states.
  static const Duration transitionDuration = Duration(milliseconds: 500);

  /// Duration of inactivity before the idle loop activates.
  static const Duration idleTimeout = Duration(seconds: 5);

  /// Target frame rate for animations (60 FPS = ~16.67ms per frame).
  static const int targetFps = 60;

  // --- State ---

  CharacterState _currentState;
  bool _isTransitioning = false;
  bool _isIdleLoopActive = false;
  bool _disposed = false;
  Offset _eyeTrackingTarget = Offset.zero;

  // --- Streams ---

  final StreamController<CharacterState> _stateController =
      StreamController<CharacterState>.broadcast();

  final StreamController<CharacterEngineError> _errorController =
      StreamController<CharacterEngineError>.broadcast();

  // --- Timers ---

  Timer? _idleTimer;
  Timer? _transitionTimer;

  /// Creates a [CharacterEngine] with an optional initial state.
  ///
  /// Defaults to [CharacterState.idle].
  CharacterEngine({CharacterState initialState = CharacterState.idle})
      : _currentState = initialState {
    _resetIdleTimer();
  }

  // ---------------------------------------------------------------------------
  // ICharacterEngine implementation
  // ---------------------------------------------------------------------------

  @override
  CharacterState get currentState => _currentState;

  @override
  bool get isIdleLoopActive => _isIdleLoopActive;

  @override
  Stream<CharacterState> get stateStream => _stateController.stream;

  @override
  Stream<CharacterEngineError> get errorStream => _errorController.stream;

  /// The current eye-tracking target offset.
  Offset get eyeTrackingTarget => _eyeTrackingTarget;

  @override
  void setState(CharacterState state) {
    _assertNotDisposed();

    // Setting the same state is a no-op.
    if (state == _currentState) return;

    // Validate transition — flat state machine allows all transitions.
    if (!_isValidTransition(_currentState, state)) {
      _errorController.add(
        CharacterEngineError.invalidTransition(from: _currentState, to: state),
      );
      return;
    }

    _performTransition(state);
  }

  @override
  void playAnimation(AnimationType type, {Duration? duration}) {
    _assertNotDisposed();
    _recordInteraction();

    // Logic-layer placeholder — actual Rive playback will be wired later.
    // For now, we track that an animation was requested.
  }

  @override
  void setEyeTrackingTarget(Offset target) {
    _assertNotDisposed();
    _eyeTrackingTarget = target;
    _recordInteraction();
  }

  @override
  void startIdleLoop() {
    _assertNotDisposed();
    if (_isIdleLoopActive) return;

    _isIdleLoopActive = true;
    // In a full implementation this would trigger the Rive idle state machine.
    // For the logic layer, we just track the flag.
  }

  @override
  void stopAllAnimations() {
    _assertNotDisposed();
    _isIdleLoopActive = false;
    _cancelTransition();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _idleTimer?.cancel();
    _transitionTimer?.cancel();
    _stateController.close();
    _errorController.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Validates whether transitioning from [from] to [to] is allowed.
  ///
  /// The state machine is flat: all states can transition to any other state.
  /// Only transitioning to the same state is handled as a no-op above.
  bool _isValidTransition(CharacterState from, CharacterState to) {
    // Flat state machine — all transitions are valid.
    return true;
  }

  /// Performs the interpolation transition from current state to [target].
  ///
  /// Uses a timer to simulate the 500ms transition duration.
  /// During transition, the engine is marked as transitioning.
  /// After the transition completes, emits the new state on [stateStream].
  void _performTransition(CharacterState target) {
    // Cancel any in-progress transition.
    _cancelTransition();

    _isTransitioning = true;
    _isIdleLoopActive = false;

    // Simulate 500ms interpolation.
    // In the full Rive implementation, this would drive blend weights
    // at 60 FPS (~30 frames over 500ms).
    _transitionTimer = Timer(transitionDuration, () {
      _isTransitioning = false;
      _currentState = target;
      _stateController.add(target);
      _resetIdleTimer();
    });

    _recordInteraction();
  }

  /// Cancels any in-progress transition timer.
  void _cancelTransition() {
    _transitionTimer?.cancel();
    _transitionTimer = null;
    _isTransitioning = false;
  }

  /// Records an interaction, resetting the idle timer.
  void _recordInteraction() {
    _isIdleLoopActive = false;
    _resetIdleTimer();
  }

  /// Resets the idle timer. After [idleTimeout] of no interaction,
  /// the idle loop starts automatically.
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, () {
      if (!_disposed && !_isTransitioning) {
        startIdleLoop();
      }
    });
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError('CharacterEngine has been disposed.');
    }
  }
}
