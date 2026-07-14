import '../../../domain/entities/emotion_state.dart';

/// Categorization of time elapsed since the user's last session.
///
/// Used by the Emotion Engine to factor into wake-up emotion calculation
/// per Requirement 12.2.
enum TimeSinceLastSession {
  /// Less than 1 hour since last interaction.
  lessThanOneHour,

  /// Between 1 and 24 hours since last interaction.
  oneToTwentyFourHours,

  /// More than 24 hours but less than 7 days.
  moreThanTwentyFourHours,

  /// More than 7 days since last interaction.
  moreThanSevenDays,
}

/// Contextual greeting data delivered by the Character Engine
/// after the wake animation completes.
class WakeGreeting {
  /// The greeting text reflecting the current emotional state.
  final String text;

  /// The emotion that the greeting reflects.
  final EmotionState emotion;

  /// Whether this greeting uses a static pose (animation timed out).
  final bool isStaticPose;

  const WakeGreeting({
    required this.text,
    required this.emotion,
    this.isStaticPose = false,
  });
}

/// States for the Startup BLoC.
///
/// Represents the progression through the app startup and wake sequence.
sealed class StartupState {
  const StartupState();
}

/// Initial state before startup begins.
class StartupInitial extends StartupState {
  const StartupInitial();
}

/// Session is being validated via Supabase Auth.
class StartupValidatingSession extends StartupState {
  const StartupValidatingSession();
}

/// Session validation failed — redirect to auth flow.
///
/// Per Requirement 12.4: no wake animation is played.
class StartupAuthRequired extends StartupState {
  const StartupAuthRequired();
}

/// Retrieving companion state from the backend.
class StartupLoadingCompanionState extends StartupState {
  const StartupLoadingCompanionState();
}

/// Wake animation is playing.
class StartupPlayingWakeAnimation extends StartupState {
  /// The calculated emotion for the wake sequence.
  final EmotionState emotion;

  const StartupPlayingWakeAnimation({required this.emotion});
}

/// Startup complete — greeting is ready.
class StartupComplete extends StartupState {
  /// The contextual greeting delivered after wake-up.
  final WakeGreeting greeting;

  const StartupComplete({required this.greeting});
}

/// An error occurred during startup (non-auth related).
class StartupError extends StartupState {
  final String message;

  const StartupError({required this.message});
}
