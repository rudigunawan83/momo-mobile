import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/domain/engines/emotion_context.dart';
import 'package:momo_app/domain/engines/emotion_engine.dart';
import 'package:momo_app/domain/engines/i_emotion_engine.dart';
import 'package:momo_app/domain/entities/emotion_state.dart';
import 'package:momo_app/domain/entities/emotion_type.dart';

void main() {
  late EmotionEngine engine;

  setUp(() {
    engine = EmotionEngine();
  });

  tearDown(() {
    engine.dispose();
  });

  group('calculateEmotion', () {
    test('maps positive sentiment to positive valence', () {
      final context = EmotionContext(
        sentimentScore: 0.8,
        timeOfDay: DateTime(2024, 1, 1, 14, 0), // 14:00 - no sleepiness
      );

      final result = engine.calculateEmotion(context);

      expect(result.valence, 0.8);
      expect(result.arousal, 0.8); // abs(0.8)
      expect(result.primary, EmotionType.excited);
    });

    test('maps negative sentiment to negative valence', () {
      final context = EmotionContext(
        sentimentScore: -0.7,
        timeOfDay: DateTime(2024, 1, 1, 14, 0),
      );

      final result = engine.calculateEmotion(context);

      expect(result.valence, -0.7);
      expect(result.arousal, 0.7); // abs(-0.7)
      expect(result.primary, EmotionType.angry);
    });

    test('maps low sentiment to low-arousal negative emotion (sad)', () {
      final context = EmotionContext(
        sentimentScore: -0.4,
        timeOfDay: DateTime(2024, 1, 1, 14, 0),
      );

      final result = engine.calculateEmotion(context);

      expect(result.valence, -0.4);
      expect(result.arousal, 0.4); // abs(-0.4) < 0.5
      expect(result.primary, EmotionType.sad);
    });

    test('maps near-zero sentiment to neutral when intensity below threshold',
        () {
      final context = EmotionContext(
        sentimentScore: 0.1,
        timeOfDay: DateTime(2024, 1, 1, 14, 0),
      );

      final result = engine.calculateEmotion(context);

      // intensity = (0.1 + 0.1) / 2 = 0.1 < 0.3
      expect(result.primary, EmotionType.neutral);
    });

    test('derives arousal from absolute sentiment score', () {
      final context = EmotionContext(
        sentimentScore: -0.6,
        timeOfDay: DateTime(2024, 1, 1, 14, 0),
      );

      final result = engine.calculateEmotion(context);

      expect(result.arousal, 0.6);
    });

    test('all output values are within valid bounds', () {
      final context = EmotionContext(
        sentimentScore: 0.95,
        timeOfDay: DateTime(2024, 1, 1, 14, 0),
      );

      final result = engine.calculateEmotion(context);

      expect(result.intensity, inInclusiveRange(0.0, 1.0));
      expect(result.valence, inInclusiveRange(-1.0, 1.0));
      expect(result.arousal, inInclusiveRange(0.0, 1.0));
    });
  });

  group('calculateEmotion - time-of-day sleepiness modifier', () {
    test('reduces arousal by 0.2 at 23:00', () {
      final context = EmotionContext(
        sentimentScore: 0.8,
        timeOfDay: DateTime(2024, 1, 1, 23, 0),
      );

      final result = engine.calculateEmotion(context);

      // arousal = abs(0.8) - 0.2 = 0.6
      expect(result.arousal, closeTo(0.6, 0.001));
    });

    test('reduces arousal by 0.2 at 03:00', () {
      final context = EmotionContext(
        sentimentScore: 0.8,
        timeOfDay: DateTime(2024, 1, 1, 3, 0),
      );

      final result = engine.calculateEmotion(context);

      // arousal = abs(0.8) - 0.2 = 0.6
      expect(result.arousal, closeTo(0.6, 0.001));
    });

    test('does not reduce arousal at 14:00', () {
      final context = EmotionContext(
        sentimentScore: 0.8,
        timeOfDay: DateTime(2024, 1, 1, 14, 0),
      );

      final result = engine.calculateEmotion(context);

      expect(result.arousal, 0.8);
    });

    test('sets primary to sleepy when nighttime and intensity < 0.3', () {
      final context = EmotionContext(
        sentimentScore: 0.1,
        timeOfDay: DateTime(2024, 1, 1, 23, 0),
      );

      final result = engine.calculateEmotion(context);

      // intensity = (0.1 + arousal_after_modifier) / 2
      // arousal_after = 0.1 - 0.2 = 0.0 (clamped)
      // intensity = (0.1 + 0.0) / 2 = 0.05 < 0.3
      expect(result.primary, EmotionType.sleepy);
    });

    test('does not set sleepy at night when intensity >= 0.3', () {
      final context = EmotionContext(
        sentimentScore: 0.9,
        timeOfDay: DateTime(2024, 1, 1, 23, 0),
      );

      final result = engine.calculateEmotion(context);

      expect(result.primary, isNot(EmotionType.sleepy));
    });

    test('clamps arousal to 0.0 when sleepiness modifier exceeds arousal', () {
      final context = EmotionContext(
        sentimentScore: 0.1,
        timeOfDay: DateTime(2024, 1, 1, 22, 0),
      );

      final result = engine.calculateEmotion(context);

      // arousal = abs(0.1) - 0.2 = -0.1 → clamped to 0.0
      expect(result.arousal, 0.0);
    });
  });

  group('blendEmotions', () {
    test('returns current state unchanged when deltaTime <= 0', () {
      final current = EmotionState(
        primary: EmotionType.happy,
        intensity: 0.8,
        valence: 0.6,
        arousal: 0.7,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );
      final target = EmotionState(
        primary: EmotionType.sad,
        intensity: 0.3,
        valence: -0.5,
        arousal: 0.2,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      );

      final result = engine.blendEmotions(current, target, 0.0);

      expect(result, current);
    });

    test('returns current state when deltaTime is negative', () {
      final current = EmotionState(
        primary: EmotionType.happy,
        intensity: 0.8,
        valence: 0.6,
        arousal: 0.7,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );
      final target = EmotionState(
        primary: EmotionType.sad,
        intensity: 0.3,
        valence: -0.5,
        arousal: 0.2,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      );

      final result = engine.blendEmotions(current, target, -1.0);

      expect(result, current);
    });

    test('converges toward target with large deltaTime', () {
      final current = EmotionState(
        primary: EmotionType.neutral,
        intensity: 0.5,
        valence: 0.0,
        arousal: 0.3,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );
      final target = EmotionState(
        primary: EmotionType.happy,
        intensity: 0.9,
        valence: 0.8,
        arousal: 0.7,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      );

      // Large deltaTime → factor ≈ 1.0
      final result = engine.blendEmotions(current, target, 100.0);

      // With very large deltaTime, factor → 1, result → target
      expect(result.valence, closeTo(target.valence, 0.01));
      expect(result.arousal, closeTo(target.arousal, 0.01));
      expect(result.intensity, closeTo(target.intensity, 0.01));
    });

    test('applies exponential interpolation formula correctly', () {
      final current = EmotionState(
        primary: EmotionType.neutral,
        intensity: 0.5,
        valence: 0.0,
        arousal: 0.3,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );
      final target = EmotionState(
        primary: EmotionType.happy,
        intensity: 0.9,
        valence: 0.8,
        arousal: 0.9,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      );

      const deltaTime = 0.5;
      final expectedFactor = 1.0 - math.exp(-2.0 * deltaTime);

      final result = engine.blendEmotions(current, target, deltaTime);

      final expectedValence =
          current.valence + (target.valence - current.valence) * expectedFactor;
      final expectedArousal =
          current.arousal + (target.arousal - current.arousal) * expectedFactor;
      final expectedIntensity = current.intensity +
          (target.intensity - current.intensity) * expectedFactor;

      expect(result.valence, closeTo(expectedValence, 0.001));
      expect(result.arousal, closeTo(expectedArousal, 0.001));
      expect(result.intensity, closeTo(expectedIntensity, 0.001));
    });

    test('blended values stay within valid bounds', () {
      final current = EmotionState(
        primary: EmotionType.excited,
        intensity: 1.0,
        valence: 1.0,
        arousal: 1.0,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );
      final target = EmotionState(
        primary: EmotionType.sad,
        intensity: 0.0,
        valence: -1.0,
        arousal: 0.0,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      );

      final result = engine.blendEmotions(current, target, 0.3);

      expect(result.intensity, inInclusiveRange(0.0, 1.0));
      expect(result.valence, inInclusiveRange(-1.0, 1.0));
      expect(result.arousal, inInclusiveRange(0.0, 1.0));
    });

    test('maps to neutral when blended intensity < neutralThreshold', () {
      final current = EmotionState(
        primary: EmotionType.happy,
        intensity: 0.1,
        valence: 0.1,
        arousal: 0.1,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );
      final target = EmotionState(
        primary: EmotionType.sad,
        intensity: 0.1,
        valence: -0.1,
        arousal: 0.1,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      );

      final result = engine.blendEmotions(current, target, 0.5);

      // Both intensities are 0.1 < 0.3, blend will also be < 0.3
      expect(result.primary, EmotionType.neutral);
    });
  });

  group('blendEmotions - boundary factor cases', () {
    test('factor 0 returns current (very tiny deltaTime)', () {
      final current = EmotionState(
        primary: EmotionType.happy,
        intensity: 0.8,
        valence: 0.6,
        arousal: 0.7,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );
      final target = EmotionState(
        primary: EmotionType.sad,
        intensity: 0.3,
        valence: -0.5,
        arousal: 0.2,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      );

      // Extremely small deltaTime → factor ≈ 0
      final result = engine.blendEmotions(current, target, 0.0000001);

      // Result should be essentially the same as current
      expect(result.valence, closeTo(current.valence, 0.001));
      expect(result.arousal, closeTo(current.arousal, 0.001));
      expect(result.intensity, closeTo(current.intensity, 0.001));
    });

    test('factor 1 returns target (very large deltaTime)', () {
      final current = EmotionState(
        primary: EmotionType.neutral,
        intensity: 0.5,
        valence: 0.0,
        arousal: 0.3,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );
      final target = EmotionState(
        primary: EmotionType.excited,
        intensity: 0.9,
        valence: 0.8,
        arousal: 0.9,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      );

      // Very large deltaTime → factor ≈ 1
      final result = engine.blendEmotions(current, target, 50.0);

      expect(result.valence, closeTo(target.valence, 0.001));
      expect(result.arousal, closeTo(target.arousal, 0.001));
      expect(result.intensity, closeTo(target.intensity, 0.001));
    });
  });

  group('updateFromConversation', () {
    test('emits updated state on emotionStream', () async {
      final event = ConversationEvent(
        sentimentScore: 0.7,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      );

      // Listen for the emission
      final future = engine.emotionStream.first;

      engine.updateFromConversation(event);

      final emitted = await future;
      expect(emitted.valence, inInclusiveRange(-1.0, 1.0));
      expect(emitted.arousal, inInclusiveRange(0.0, 1.0));
      expect(emitted.intensity, inInclusiveRange(0.0, 1.0));
    });

    test('updates internal current state', () {
      // First update to set a baseline state with an earlier timestamp
      engine.updateFromConversation(ConversationEvent(
        sentimentScore: 0.0,
        timestamp: DateTime(2024, 1, 1, 13, 0),
      ));

      // Second update with different sentiment and later timestamp
      engine.updateFromConversation(ConversationEvent(
        sentimentScore: 0.8,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      ));

      // After blending with positive sentiment, valence should be positive
      expect(engine.currentState.valence, greaterThan(0.0));
    });
  });

  group('emotionStream', () {
    test('is a broadcast stream', () {
      // Should allow multiple listeners without error
      engine.emotionStream.listen((_) {});
      engine.emotionStream.listen((_) {});
    });

    test('emits consecutive updates', () async {
      final events = <EmotionState>[];
      engine.emotionStream.listen(events.add);

      engine.updateFromConversation(ConversationEvent(
        sentimentScore: 0.5,
        timestamp: DateTime(2024, 1, 1, 14, 0),
      ));
      engine.updateFromConversation(ConversationEvent(
        sentimentScore: -0.5,
        timestamp: DateTime(2024, 1, 1, 14, 1),
      ));

      // Give stream time to emit
      await Future<void>.delayed(Duration.zero);

      expect(events.length, 2);
    });
  });
}
