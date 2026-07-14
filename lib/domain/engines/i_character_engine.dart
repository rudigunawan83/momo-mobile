import 'dart:ui' show Offset;

import '../entities/character_state.dart';
import 'animation_type.dart';
import 'character_engine_error.dart';

/// Interface for the Character Engine that manages Momo's visual state,
/// animations, and transitions.
///
/// The Character Engine drives Rive animations based on emotional state,
/// handles smooth transitions between animation states, implements eye
/// tracking, and manages idle behaviors.
///
/// Maintains a 60 FPS rendering target during all operations.
abstract class ICharacterEngine {
  /// Transitions the character to the given [state].
  ///
  /// The transition uses 500ms interpolation to smoothly blend between
  /// the current and target state without dropping below 60 FPS.
  ///
  /// If the transition is invalid, the engine remains in the current state
  /// and emits a [CharacterEngineError] on [errorStream].
  ///
  /// Emits the new state on [stateStream] upon successful transition.
  void setState(CharacterState state);

  /// Plays a specific animation type with an optional custom [duration].
  ///
  /// If no [duration] is provided, the animation plays for its default length.
  void playAnimation(AnimationType type, {Duration? duration});

  /// Updates the eye-tracking target to the given screen [target] offset.
  ///
  /// The eyes should reach the target position within 100ms.
  void setEyeTrackingTarget(Offset target);

  /// Starts the idle loop (blink, breathe, look-around).
  ///
  /// The idle loop activates automatically after 5 seconds of no interaction,
  /// but can also be started manually.
  void startIdleLoop();

  /// Stops all currently playing animations and resets to a neutral pose.
  void stopAllAnimations();

  /// Stream of [CharacterState] changes.
  ///
  /// Emits the new state whenever a successful transition occurs.
  Stream<CharacterState> get stateStream;

  /// Stream of errors encountered during engine operations.
  ///
  /// Emits [CharacterEngineError] when invalid operations are attempted,
  /// such as invalid state transitions.
  Stream<CharacterEngineError> get errorStream;

  /// The current [CharacterState] of the engine.
  CharacterState get currentState;

  /// Whether the idle loop is currently active.
  bool get isIdleLoopActive;

  /// Disposes of all resources held by the engine.
  ///
  /// After calling dispose, the engine should not be used.
  void dispose();
}
