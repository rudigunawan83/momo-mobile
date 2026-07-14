/// Represents the types of animations the Character Engine can play.
///
/// These map to Rive animation state machines within the artboard.
enum AnimationType {
  /// Idle loop: blinking, breathing, subtle look-around.
  idle,

  /// Transition animation between two states.
  transition,

  /// Lip-sync animation driven by audio stream.
  lipSync,

  /// One-shot expression animation (e.g., surprise reaction).
  expression,

  /// Eye-tracking animation following a target offset.
  eyeTracking,
}
