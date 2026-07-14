/// Events for the Startup BLoC.
///
/// These represent the lifecycle events during app startup and
/// the wake-up sequence.
sealed class StartupEvent {
  const StartupEvent();
}

/// Triggered when the app is opened and startup should begin.
///
/// Kicks off session validation → companion state retrieval →
/// emotion calculation → wake animation sequence.
class AppOpened extends StartupEvent {
  const AppOpened();
}

/// Triggered when the wake animation completes successfully.
class WakeAnimationCompleted extends StartupEvent {
  const WakeAnimationCompleted();
}

/// Triggered when the wake animation exceeds the 5-second timeout.
///
/// Per Requirement 12.6: skip to greeting delivery with static pose.
class WakeAnimationTimedOut extends StartupEvent {
  const WakeAnimationTimedOut();
}
