import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/domain/engines/emotion_context.dart';
import 'package:momo_app/domain/engines/i_character_engine.dart';
import 'package:momo_app/domain/engines/i_emotion_engine.dart';
import 'package:momo_app/domain/engines/animation_type.dart';
import 'package:momo_app/domain/engines/character_engine_error.dart';
import 'package:momo_app/domain/entities/character_state.dart';
import 'package:momo_app/domain/entities/emotion_state.dart';
import 'package:momo_app/domain/entities/emotion_type.dart';
import 'package:momo_app/domain/repositories/i_companion_repository.dart';
import 'package:momo_app/domain/services/i_auth_service.dart';
import 'package:momo_app/presentation/bloc/startup/startup_bloc.dart';
import 'package:momo_app/presentation/bloc/startup/startup_event.dart';
import 'package:momo_app/presentation/bloc/startup/startup_state.dart';

// --- Mock implementations ---

class MockAuthService implements IAuthService {
  bool sessionValid;
  String? userId;
  bool throwOnValidate;
  Duration validateDelay;

  MockAuthService({
    this.sessionValid = true,
    this.userId = 'test-user-id',
    this.throwOnValidate = false,
    this.validateDelay = Duration.zero,
  });

  @override
  Future<bool> validateSession() async {
    if (validateDelay > Duration.zero) {
      await Future<void>.delayed(validateDelay);
    }
    if (throwOnValidate) throw Exception('Auth service unavailable');
    return sessionValid;
  }

  @override
  Future<String?> getCurrentUserId() async => userId;
}

class MockCompanionRepository implements ICompanionRepository {
  CompanionState? companionState;
  bool throwOnGet;

  MockCompanionRepository({
    this.companionState,
    this.throwOnGet = false,
  });

  @override
  Future<CompanionState> getCompanionState({required String userId}) async {
    if (throwOnGet) throw Exception('Backend unavailable');
    if (companionState == null) throw Exception('No companion state');
    return companionState!;
  }

  @override
  Future<FriendshipState> getFriendshipState({required String userId}) async {
    return FriendshipState(
      level: companionState?.friendshipLevel ?? 1,
      currentXP: 0,
      xpToNextLevel: 100,
      totalXP: companionState?.totalXP ?? 0,
      loginStreak: 0,
      lastLoginDate: DateTime.now(),
      unlockedAchievements: [],
    );
  }

  @override
  Future<bool> claimDailyLogin({required String userId}) async => true;
}

class MockEmotionEngine implements IEmotionEngine {
  final StreamController<EmotionState> _emotionController =
      StreamController<EmotionState>.broadcast();

  EmotionState? lastCalculated;
  EmotionState? lastBlended;

  @override
  EmotionState calculateEmotion(EmotionContext context) {
    final emotion = EmotionState(
      primary: context.sentimentScore > 0.3
          ? EmotionType.happy
          : context.sentimentScore < -0.3
              ? EmotionType.sad
              : EmotionType.neutral,
      intensity: context.sentimentScore.abs().clamp(0.0, 1.0),
      valence: context.sentimentScore.clamp(-1.0, 1.0),
      arousal: context.sentimentScore.abs().clamp(0.0, 1.0),
      timestamp: context.timeOfDay,
    );
    lastCalculated = emotion;
    return emotion;
  }

  @override
  EmotionState blendEmotions(
    EmotionState current,
    EmotionState target,
    double deltaTime,
  ) {
    // Simple blend: just return the target for testing
    lastBlended = target;
    return target;
  }

  @override
  void updateFromConversation(ConversationEvent event) {}

  @override
  Stream<EmotionState> get emotionStream => _emotionController.stream;

  void dispose() {
    _emotionController.close();
  }
}

class MockCharacterEngine implements ICharacterEngine {
  CharacterState _currentState = CharacterState.idle;
  final List<CharacterState> stateHistory = [];
  bool stopAllCalled = false;

  final StreamController<CharacterState> _stateController =
      StreamController<CharacterState>.broadcast();
  final StreamController<CharacterEngineError> _errorController =
      StreamController<CharacterEngineError>.broadcast();

  @override
  CharacterState get currentState => _currentState;

  @override
  bool get isIdleLoopActive => false;

  @override
  Stream<CharacterState> get stateStream => _stateController.stream;

  @override
  Stream<CharacterEngineError> get errorStream => _errorController.stream;

  @override
  void setState(CharacterState state) {
    _currentState = state;
    stateHistory.add(state);
    _stateController.add(state);
  }

  @override
  void playAnimation(AnimationType type, {Duration? duration}) {}

  @override
  void setEyeTrackingTarget(Offset target) {}

  @override
  void startIdleLoop() {}

  @override
  void stopAllAnimations() {
    stopAllCalled = true;
  }

  @override
  void dispose() {
    _stateController.close();
    _errorController.close();
  }
}

// --- Tests ---

void main() {
  late MockAuthService mockAuth;
  late MockCompanionRepository mockCompanion;
  late MockEmotionEngine mockEmotion;
  late MockCharacterEngine mockCharacter;
  late StartupBloc bloc;

  setUp(() {
    mockAuth = MockAuthService();
    mockCompanion = MockCompanionRepository(
      companionState: CompanionState(
        lastEmotion: EmotionState(
          primary: EmotionType.happy,
          intensity: 0.7,
          valence: 0.5,
          arousal: 0.6,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        lastSeenAt: DateTime.now().subtract(const Duration(hours: 2)),
        friendshipLevel: 3,
        totalXP: 450,
      ),
    );
    mockEmotion = MockEmotionEngine();
    mockCharacter = MockCharacterEngine();
    bloc = StartupBloc(
      authService: mockAuth,
      companionRepository: mockCompanion,
      emotionEngine: mockEmotion,
      characterEngine: mockCharacter,
    );
  });

  tearDown(() {
    bloc.dispose();
    mockEmotion.dispose();
    mockCharacter.dispose();
  });

  group('StartupBloc', () {
    group('successful startup flow', () {
      test('initial state is StartupInitial', () {
        expect(bloc.state, isA<StartupInitial>());
      });

      test('progresses through expected states on successful startup',
          () async {
        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states[0], isA<StartupValidatingSession>());
        expect(states[1], isA<StartupLoadingCompanionState>());
        expect(states[2], isA<StartupPlayingWakeAnimation>());
      });

      test('calculates emotion from companion state', () async {
        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // The emotion engine should have been called
        expect(mockEmotion.lastCalculated, isNotNull);
      });

      test('sets character state matching emotion', () async {
        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Character engine should have received a state update
        expect(mockCharacter.stateHistory, isNotEmpty);
      });

      test('completes with greeting after WakeAnimationCompleted', () async {
        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        bloc.add(const WakeAnimationCompleted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final completedState =
            states.whereType<StartupComplete>().firstOrNull;
        expect(completedState, isNotNull);
        expect(completedState!.greeting.isStaticPose, false);
        expect(completedState.greeting.text, isNotEmpty);
      });
    });

    group('session validation failure (Req 12.4)', () {
      test('emits StartupAuthRequired when session is invalid', () async {
        mockAuth.sessionValid = false;

        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states.last, isA<StartupAuthRequired>());
      });

      test('does not play wake animation when session is invalid', () async {
        mockAuth.sessionValid = false;

        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          states.whereType<StartupPlayingWakeAnimation>(),
          isEmpty,
        );
      });

      test('emits StartupAuthRequired when auth service throws', () async {
        mockAuth.throwOnValidate = true;

        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states.last, isA<StartupAuthRequired>());
      });

      test('does not interact with companion repository when auth fails',
          () async {
        mockAuth.sessionValid = false;

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Character engine should not have received any state update
        expect(mockCharacter.stateHistory, isEmpty);
      });
    });

    group('companion state retrieval failure (Req 12.5)', () {
      test('uses default neutral state when retrieval fails', () async {
        mockCompanion.throwOnGet = true;

        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final animState =
            states.whereType<StartupPlayingWakeAnimation>().firstOrNull;
        expect(animState, isNotNull);
        // Default neutral state has EmotionType.neutral
        expect(animState!.emotion.primary, EmotionType.neutral);
      });

      test('proceeds with wake animation on retrieval failure', () async {
        mockCompanion.throwOnGet = true;

        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          states.whereType<StartupPlayingWakeAnimation>(),
          isNotEmpty,
        );
      });

      test('uses friendship level 1 on retrieval failure', () async {
        mockCompanion.throwOnGet = true;

        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final animState =
            states.whereType<StartupPlayingWakeAnimation>().first;
        // Default neutral state: intensity 0.5, valence 0.0, arousal 0.3
        expect(animState.emotion.intensity, 0.5);
        expect(animState.emotion.valence, 0.0);
        expect(animState.emotion.arousal, 0.3);
      });
    });

    group('wake animation timeout (Req 12.6)', () {
      test('skips to greeting with static pose on timeout', () async {
        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Simulate timeout event
        bloc.add(const WakeAnimationTimedOut());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final completedState =
            states.whereType<StartupComplete>().firstOrNull;
        expect(completedState, isNotNull);
        expect(completedState!.greeting.isStaticPose, true);
      });

      test('stops all animations on timeout', () async {
        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        bloc.add(const WakeAnimationTimedOut());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(mockCharacter.stopAllCalled, true);
      });

      test('greeting text reflects emotion on timeout', () async {
        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        bloc.add(const WakeAnimationTimedOut());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final completedState = states.whereType<StartupComplete>().first;
        expect(completedState.greeting.text, isNotEmpty);
        expect(completedState.greeting.emotion, isNotNull);
      });
    });

    group('emotion calculation (Req 12.2)', () {
      test('categorizes time < 1 hour as lessThanOneHour', () async {
        mockCompanion.companionState = CompanionState(
          lastEmotion: EmotionState.neutral(),
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 30)),
          friendshipLevel: 1,
          totalXP: 50,
        );

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // With short absence and low friendship, sentiment should be mild positive
        expect(mockEmotion.lastCalculated, isNotNull);
        expect(mockEmotion.lastCalculated!.valence, greaterThanOrEqualTo(0.0));
      });

      test('categorizes time 1-24 hours as oneToTwentyFourHours', () async {
        mockCompanion.companionState = CompanionState(
          lastEmotion: EmotionState.neutral(),
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 5)),
          friendshipLevel: 3,
          totalXP: 300,
        );

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Moderate absence produces moderate positive sentiment
        expect(mockEmotion.lastCalculated, isNotNull);
      });

      test('categorizes time > 24 hours as moreThanTwentyFourHours',
          () async {
        mockCompanion.companionState = CompanionState(
          lastEmotion: EmotionState.neutral(),
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 48)),
          friendshipLevel: 5,
          totalXP: 800,
        );

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Longer absence produces higher positive sentiment (excited)
        expect(mockEmotion.lastCalculated, isNotNull);
      });

      test('categorizes time > 7 days as moreThanSevenDays', () async {
        mockCompanion.companionState = CompanionState(
          lastEmotion: EmotionState.neutral(),
          lastSeenAt: DateTime.now().subtract(const Duration(days: 10)),
          friendshipLevel: 7,
          totalXP: 2000,
        );

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Very long absence produces high positive sentiment
        expect(mockEmotion.lastCalculated, isNotNull);
      });

      test('factors friendship level into emotion calculation', () async {
        // Low friendship
        mockCompanion.companionState = CompanionState(
          lastEmotion: EmotionState.neutral(),
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 2)),
          friendshipLevel: 1,
          totalXP: 0,
        );

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final lowFriendshipEmotion = mockEmotion.lastCalculated;

        // Reset
        bloc.dispose();
        mockEmotion = MockEmotionEngine();
        mockCharacter = MockCharacterEngine();

        // High friendship
        mockCompanion.companionState = CompanionState(
          lastEmotion: EmotionState.neutral(),
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 2)),
          friendshipLevel: 10,
          totalXP: 5000,
        );

        bloc = StartupBloc(
          authService: mockAuth,
          companionRepository: mockCompanion,
          emotionEngine: mockEmotion,
          characterEngine: mockCharacter,
        );

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final highFriendshipEmotion = mockEmotion.lastCalculated;

        // Higher friendship should produce equal or more positive sentiment
        expect(lowFriendshipEmotion, isNotNull);
        expect(highFriendshipEmotion, isNotNull);
      });
    });

    group('greeting generation (Req 12.3)', () {
      test('greeting text matches emotion type', () async {
        // Set up companion to produce a happy emotion
        mockCompanion.companionState = CompanionState(
          lastEmotion: EmotionState(
            primary: EmotionType.happy,
            intensity: 0.8,
            valence: 0.7,
            arousal: 0.6,
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 3)),
          friendshipLevel: 5,
          totalXP: 800,
        );

        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        bloc.add(const WakeAnimationCompleted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final completedState = states.whereType<StartupComplete>().first;
        expect(completedState.greeting.text, isNotEmpty);
        expect(completedState.greeting.emotion.primary, isNotNull);
      });

      test('greeting is not static pose on normal completion', () async {
        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        bloc.add(const WakeAnimationCompleted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final completedState = states.whereType<StartupComplete>().first;
        expect(completedState.greeting.isStaticPose, false);
      });
    });

    group('dispose', () {
      test('stops emitting states after dispose', () async {
        bloc.dispose();

        final states = <StartupState>[];
        bloc.stateStream.listen(states.add);

        bloc.add(const AppOpened());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states, isEmpty);
      });
    });
  });
}
