import 'dart:async';

import '../../../domain/engines/emotion_context.dart';
import '../../../domain/engines/i_character_engine.dart';
import '../../../domain/engines/i_emotion_engine.dart';
import '../../../domain/entities/character_state.dart';
import '../../../domain/entities/emotion_state.dart';
import '../../../domain/entities/emotion_type.dart';
import '../../../domain/repositories/i_companion_repository.dart';
import '../../../domain/services/i_auth_service.dart';
import 'startup_event.dart';
import 'startup_state.dart';

/// BLoC managing the app startup and wake-up sequence.
///
/// Orchestrates the flow:
/// 1. Validate session via Supabase Auth
/// 2. Retrieve companion state from backend
/// 3. Calculate current emotion based on last state, time since last session,
///    and friendship level
/// 4. Play wake-up animation with contextual greeting within 3 seconds
///
/// Handles failure cases:
/// - Session validation failure → redirect to auth (Req 12.4)
/// - Companion state retrieval failure → default neutral state (Req 12.5)
/// - Wake animation timeout (5s) → skip to greeting with static pose (Req 12.6)
///
/// Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6
class StartupBloc {
  final IAuthService _authService;
  final ICompanionRepository _companionRepository;
  final IEmotionEngine _emotionEngine;
  final ICharacterEngine _characterEngine;

  /// Maximum time for the entire startup sequence (Req 12.1: within 3 seconds).
  static const Duration startupTimeout = Duration(seconds: 3);

  /// Maximum time for the wake animation before skipping (Req 12.6: 5 seconds).
  static const Duration wakeAnimationTimeout = Duration(seconds: 5);

  final StreamController<StartupState> _stateController =
      StreamController<StartupState>.broadcast();

  StartupState _currentState = const StartupInitial();
  Timer? _animationTimeoutTimer;
  bool _disposed = false;

  /// Creates a [StartupBloc] with all required dependencies.
  StartupBloc({
    required IAuthService authService,
    required ICompanionRepository companionRepository,
    required IEmotionEngine emotionEngine,
    required ICharacterEngine characterEngine,
  })  : _authService = authService,
        _companionRepository = companionRepository,
        _emotionEngine = emotionEngine,
        _characterEngine = characterEngine;

  /// The current state of the startup sequence.
  StartupState get state => _currentState;

  /// Stream of state changes during startup.
  Stream<StartupState> get stateStream => _stateController.stream;

  /// Dispatches an event to the BLoC.
  void add(StartupEvent event) {
    if (_disposed) return;

    switch (event) {
      case AppOpened():
        _onAppOpened();
      case WakeAnimationCompleted():
        _onWakeAnimationCompleted();
      case WakeAnimationTimedOut():
        _onWakeAnimationTimedOut();
    }
  }

  /// Handles the [AppOpened] event — main startup orchestration.
  Future<void> _onAppOpened() async {
    // Step 1: Validate session
    _emit(const StartupValidatingSession());

    final bool sessionValid;
    try {
      sessionValid = await _authService.validateSession();
    } catch (_) {
      // Any error during validation → treat as invalid session
      _emit(const StartupAuthRequired());
      return;
    }

    if (!sessionValid) {
      // Requirement 12.4: redirect to auth without wake animation
      _emit(const StartupAuthRequired());
      return;
    }

    // Step 2: Retrieve companion state
    _emit(const StartupLoadingCompanionState());

    CompanionState? companionState;
    String? userId;

    try {
      userId = await _authService.getCurrentUserId();
      if (userId != null) {
        companionState =
            await _companionRepository.getCompanionState(userId: userId);
      }
    } catch (_) {
      // Requirement 12.5: use default neutral state on retrieval failure
      companionState = null;
    }

    // Step 3: Calculate current emotion
    final EmotionState currentEmotion;
    if (companionState != null) {
      currentEmotion = _calculateWakeEmotion(companionState);
    } else {
      // Default neutral state with friendship level 1 (Req 12.5)
      currentEmotion = EmotionState.neutral();
    }

    // Step 4: Play wake-up animation
    _emit(StartupPlayingWakeAnimation(emotion: currentEmotion));

    // Set character state to match the emotion
    final characterState = _emotionToCharacterState(currentEmotion.primary);
    _characterEngine.setState(characterState);

    // Start 5-second animation timeout (Req 12.6)
    _startAnimationTimeout(currentEmotion);
  }

  /// Handles the [WakeAnimationCompleted] event.
  ///
  /// Animation completed within timeout — deliver contextual greeting.
  void _onWakeAnimationCompleted() {
    _cancelAnimationTimeout();

    if (_currentState is! StartupPlayingWakeAnimation) return;
    final animState = _currentState as StartupPlayingWakeAnimation;

    final greeting = _generateGreeting(animState.emotion, isStaticPose: false);
    _emit(StartupComplete(greeting: greeting));
  }

  /// Handles the [WakeAnimationTimedOut] event.
  ///
  /// Requirement 12.6: skip to greeting with static pose.
  void _onWakeAnimationTimedOut() {
    if (_currentState is! StartupPlayingWakeAnimation) return;
    final animState = _currentState as StartupPlayingWakeAnimation;

    // Stop all animations and use static pose
    _characterEngine.stopAllAnimations();

    final greeting = _generateGreeting(animState.emotion, isStaticPose: true);
    _emit(StartupComplete(greeting: greeting));
  }

  /// Calculates the wake-up emotion based on companion state.
  ///
  /// Factors:
  /// - Last known emotional state
  /// - Time since last session (categorized)
  /// - Current friendship level
  ///
  /// Requirement 12.2
  EmotionState _calculateWakeEmotion(CompanionState companionState) {
    final timeSinceLast = _categorizeTimeSinceLastSession(
      DateTime.now().difference(companionState.lastSeenAt),
    );

    // Base sentiment derived from time-since-last-session and friendship level
    final double sentimentScore =
        _calculateWakeSentiment(timeSinceLast, companionState.friendshipLevel);

    // Use the Emotion Engine to calculate with time-of-day modifiers
    final context = EmotionContext(
      sentimentScore: sentimentScore,
      timeOfDay: DateTime.now(),
    );
    final targetEmotion = _emotionEngine.calculateEmotion(context);

    // Blend with the last known emotion for continuity
    final blendedEmotion = _emotionEngine.blendEmotions(
      companionState.lastEmotion,
      targetEmotion,
      0.8, // Favor the new wake-up emotion
    );

    return blendedEmotion;
  }

  /// Calculates a sentiment score based on how long the user was away
  /// and their friendship level.
  ///
  /// Higher friendship levels produce warmer (more positive) sentiments.
  /// Longer absences modulate the sentiment differently:
  /// - Short absence (< 1h): continue previous mood, slightly positive
  /// - Medium absence (1-24h): normal positive greeting
  /// - Long absence (> 24h): excited to see user
  /// - Very long absence (> 7 days): very excited, slight concern
  double _calculateWakeSentiment(
    TimeSinceLastSession timeSince,
    int friendshipLevel,
  ) {
    // Friendship modifier: higher level = warmer greeting (0.0 to 0.3 boost)
    final friendshipBoost = (friendshipLevel.clamp(1, 10) - 1) / 30.0;

    switch (timeSince) {
      case TimeSinceLastSession.lessThanOneHour:
        // Quick return — mild positive
        return (0.2 + friendshipBoost).clamp(-1.0, 1.0);
      case TimeSinceLastSession.oneToTwentyFourHours:
        // Normal session gap — standard positive greeting
        return (0.4 + friendshipBoost).clamp(-1.0, 1.0);
      case TimeSinceLastSession.moreThanTwentyFourHours:
        // Been a while — excited to see user
        return (0.6 + friendshipBoost).clamp(-1.0, 1.0);
      case TimeSinceLastSession.moreThanSevenDays:
        // Long absence — very excited
        return (0.8 + friendshipBoost).clamp(-1.0, 1.0);
    }
  }

  /// Categorizes the duration since last session into the defined buckets.
  ///
  /// Per Requirement 12.2:
  /// - Less than 1 hour
  /// - 1–24 hours
  /// - More than 24 hours
  /// - More than 7 days
  TimeSinceLastSession _categorizeTimeSinceLastSession(Duration duration) {
    if (duration.inDays >= 7) {
      return TimeSinceLastSession.moreThanSevenDays;
    } else if (duration.inHours >= 24) {
      return TimeSinceLastSession.moreThanTwentyFourHours;
    } else if (duration.inHours >= 1) {
      return TimeSinceLastSession.oneToTwentyFourHours;
    } else {
      return TimeSinceLastSession.lessThanOneHour;
    }
  }

  /// Generates a contextual greeting based on the current emotion.
  ///
  /// Requirement 12.3: greeting reflects emotional state through
  /// matching animation, expression, and greeting text.
  WakeGreeting _generateGreeting(
    EmotionState emotion, {
    required bool isStaticPose,
  }) {
    final greetingText = _getGreetingText(emotion.primary);
    return WakeGreeting(
      text: greetingText,
      emotion: emotion,
      isStaticPose: isStaticPose,
    );
  }

  /// Returns a greeting text that matches the given emotion type.
  String _getGreetingText(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return 'Hai! Senang bertemu lagi! 😊';
      case EmotionType.excited:
        return 'Wah, kamu kembali! Aku kangen! ✨';
      case EmotionType.sad:
        return 'Hei... aku senang kamu di sini...';
      case EmotionType.angry:
        return 'Oh, kamu datang juga...';
      case EmotionType.curious:
        return 'Hmm, ada yang baru hari ini? 🤔';
      case EmotionType.shy:
        return 'H-hai... selamat datang kembali...';
      case EmotionType.sleepy:
        return 'Zzz... oh, kamu ya... *nguap* 😴';
      case EmotionType.neutral:
        return 'Hai, selamat datang kembali!';
    }
  }

  /// Maps an [EmotionType] to the corresponding [CharacterState].
  CharacterState _emotionToCharacterState(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return CharacterState.happy;
      case EmotionType.sad:
        return CharacterState.sad;
      case EmotionType.angry:
        return CharacterState.angry;
      case EmotionType.curious:
        return CharacterState.curious;
      case EmotionType.shy:
        return CharacterState.shy;
      case EmotionType.sleepy:
        return CharacterState.sleepy;
      case EmotionType.neutral:
        return CharacterState.neutral;
      case EmotionType.excited:
        return CharacterState.excited;
    }
  }

  /// Starts the 5-second animation timeout timer.
  void _startAnimationTimeout(EmotionState emotion) {
    _animationTimeoutTimer = Timer(wakeAnimationTimeout, () {
      add(const WakeAnimationTimedOut());
    });
  }

  /// Cancels the animation timeout timer.
  void _cancelAnimationTimeout() {
    _animationTimeoutTimer?.cancel();
    _animationTimeoutTimer = null;
  }

  void _emit(StartupState state) {
    if (_disposed) return;
    _currentState = state;
    _stateController.add(state);
  }

  /// Disposes resources held by the BLoC.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelAnimationTimeout();
    _stateController.close();
  }
}
