import 'dart:async';
import 'dart:math' as math;

import '../entities/emotion_state.dart';
import '../entities/emotion_type.dart';
import 'emotion_context.dart';
import 'i_emotion_engine.dart';

/// Concrete implementation of [IEmotionEngine].
///
/// Calculates, blends, and emits emotional states for Momo based on
/// conversation sentiment, time-of-day, and exponential interpolation.
class EmotionEngine implements IEmotionEngine {
  /// Blend speed constant — emotions blend over ~0.5 seconds.
  static const double blendSpeed = 2.0;

  /// Threshold below which intensity maps to [EmotionType.neutral].
  static const double neutralThreshold = 0.3;

  /// Arousal reduction applied during sleepy hours (22:00–05:00).
  static const double sleepinessModifier = 0.2;

  final StreamController<EmotionState> _emotionController =
      StreamController<EmotionState>.broadcast();

  EmotionState _currentState = EmotionState.neutral();

  /// The current emotion state held by the engine.
  EmotionState get currentState => _currentState;

  @override
  Stream<EmotionState> get emotionStream => _emotionController.stream;

  @override
  EmotionState calculateEmotion(EmotionContext context) {
    // Map sentiment score directly to valence
    final double valence = context.sentimentScore;

    // Derive arousal from absolute value of sentiment score
    double arousal = context.sentimentScore.abs();

    // Calculate intensity as the magnitude of the emotion
    double intensity = (valence.abs() + arousal) / 2.0;

    // Apply time-of-day sleepiness modifier (22:00–05:00)
    final hour = context.timeOfDay.hour;
    final isSleepyHour = hour >= 22 || hour < 5;

    if (isSleepyHour) {
      arousal = (arousal - sleepinessModifier).clamp(0.0, 1.0);
    }

    // Clamp all values to valid ranges
    intensity = intensity.clamp(0.0, 1.0);
    arousal = arousal.clamp(0.0, 1.0);

    // Determine primary emotion
    EmotionType primary;
    if (isSleepyHour && intensity < neutralThreshold) {
      primary = EmotionType.sleepy;
    } else if (intensity < neutralThreshold) {
      primary = EmotionType.neutral;
    } else {
      primary = _mapValenceArousalToEmotion(valence, arousal);
    }

    return EmotionState(
      primary: primary,
      intensity: intensity,
      valence: valence.clamp(-1.0, 1.0),
      arousal: arousal,
      timestamp: context.timeOfDay,
    );
  }

  @override
  EmotionState blendEmotions(
    EmotionState current,
    EmotionState target,
    double deltaTime,
  ) {
    // Guard: deltaTime <= 0 returns current state unchanged
    if (deltaTime <= 0) {
      return current;
    }

    // Calculate exponential interpolation factor
    final double factor = 1.0 - math.exp(-blendSpeed * deltaTime);

    // Boundary case: factor effectively 0 → return current
    if (factor <= 0.0) {
      return current;
    }

    // Boundary case: factor effectively 1 → return target
    if (factor >= 1.0) {
      return target;
    }

    // Interpolate each dimension
    final double newValence =
        current.valence + (target.valence - current.valence) * factor;
    final double newArousal =
        current.arousal + (target.arousal - current.arousal) * factor;
    final double newIntensity =
        current.intensity + (target.intensity - current.intensity) * factor;

    // Clamp to valid ranges
    final double clampedValence = newValence.clamp(-1.0, 1.0);
    final double clampedArousal = newArousal.clamp(0.0, 1.0);
    final double clampedIntensity = newIntensity.clamp(0.0, 1.0);

    // Determine primary emotion from blended values
    EmotionType primary;
    if (clampedIntensity < neutralThreshold) {
      primary = EmotionType.neutral;
    } else {
      primary = _mapValenceArousalToEmotion(clampedValence, clampedArousal);
    }

    return EmotionState(
      primary: primary,
      intensity: clampedIntensity,
      valence: clampedValence,
      arousal: clampedArousal,
      timestamp: DateTime.now(),
    );
  }

  @override
  void updateFromConversation(ConversationEvent event) {
    final context = EmotionContext(
      sentimentScore: event.sentimentScore,
      timeOfDay: event.timestamp,
    );

    final targetEmotion = calculateEmotion(context);

    // Calculate elapsed time since last state update
    final deltaTime =
        event.timestamp.difference(_currentState.timestamp).inMilliseconds /
            1000.0;

    // If deltaTime is positive, blend smoothly; otherwise set directly
    if (deltaTime > 0) {
      _currentState = blendEmotions(_currentState, targetEmotion, deltaTime);
    } else {
      _currentState = targetEmotion;
    }

    _emotionController.add(_currentState);
  }

  /// Maps valence and arousal coordinates to an [EmotionType].
  ///
  /// Uses quadrant mapping:
  /// - High valence, high arousal → excited
  /// - High valence, low arousal → happy
  /// - Low valence, high arousal → angry
  /// - Low valence, low arousal → sad
  /// - Near-zero valence, high arousal → curious
  /// - Near-zero valence, low arousal → shy
  EmotionType _mapValenceArousalToEmotion(double valence, double arousal) {
    const double valenceThreshold = 0.3;
    const double arousalMidpoint = 0.5;

    if (valence > valenceThreshold) {
      // Positive valence
      if (arousal >= arousalMidpoint) {
        return EmotionType.excited;
      } else {
        return EmotionType.happy;
      }
    } else if (valence < -valenceThreshold) {
      // Negative valence
      if (arousal >= arousalMidpoint) {
        return EmotionType.angry;
      } else {
        return EmotionType.sad;
      }
    } else {
      // Neutral valence zone
      if (arousal >= arousalMidpoint) {
        return EmotionType.curious;
      } else {
        return EmotionType.shy;
      }
    }
  }

  /// Disposes internal resources. Call when the engine is no longer needed.
  void dispose() {
    _emotionController.close();
  }
}
