import '../entities/character_state.dart';

/// Error emitted when the Character Engine encounters an invalid operation.
///
/// Typically emitted on the error stream when an invalid state transition
/// is requested.
class CharacterEngineError {
  /// Human-readable description of the error.
  final String message;

  /// The state the engine was in when the error occurred.
  final CharacterState currentState;

  /// The state that was requested but could not be transitioned to.
  final CharacterState? requestedState;

  /// Timestamp when the error occurred.
  final DateTime timestamp;

  CharacterEngineError({
    required this.message,
    required this.currentState,
    this.requestedState,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates an error for an invalid state transition.
  factory CharacterEngineError.invalidTransition({
    required CharacterState from,
    required CharacterState to,
  }) {
    return CharacterEngineError(
      message: 'Invalid transition from $from to $to',
      currentState: from,
      requestedState: to,
    );
  }

  @override
  String toString() =>
      'CharacterEngineError(message: $message, currentState: $currentState, '
      'requestedState: $requestedState)';
}
