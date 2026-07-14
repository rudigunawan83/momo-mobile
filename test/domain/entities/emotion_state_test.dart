import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/domain/entities/emotion_state.dart';
import 'package:momo_app/domain/entities/emotion_type.dart';

void main() {
  group('EmotionState', () {
    group('validation', () {
      test('creates successfully with valid values', () {
        final state = EmotionState(
          primary: EmotionType.happy,
          intensity: 0.8,
          valence: 0.5,
          arousal: 0.6,
          timestamp: DateTime.now(),
        );

        expect(state.primary, EmotionType.happy);
        expect(state.intensity, 0.8);
        expect(state.valence, 0.5);
        expect(state.arousal, 0.6);
      });

      test('accepts boundary values for intensity (0.0 and 1.0)', () {
        final stateMin = EmotionState(
          primary: EmotionType.neutral,
          intensity: 0.0,
          valence: 0.0,
          arousal: 0.0,
          timestamp: DateTime.now(),
        );
        expect(stateMin.intensity, 0.0);

        final stateMax = EmotionState(
          primary: EmotionType.excited,
          intensity: 1.0,
          valence: 0.0,
          arousal: 0.0,
          timestamp: DateTime.now(),
        );
        expect(stateMax.intensity, 1.0);
      });

      test('accepts boundary values for valence (-1.0 and 1.0)', () {
        final stateMin = EmotionState(
          primary: EmotionType.sad,
          intensity: 0.5,
          valence: -1.0,
          arousal: 0.5,
          timestamp: DateTime.now(),
        );
        expect(stateMin.valence, -1.0);

        final stateMax = EmotionState(
          primary: EmotionType.happy,
          intensity: 0.5,
          valence: 1.0,
          arousal: 0.5,
          timestamp: DateTime.now(),
        );
        expect(stateMax.valence, 1.0);
      });

      test('accepts boundary values for arousal (0.0 and 1.0)', () {
        final stateMin = EmotionState(
          primary: EmotionType.sleepy,
          intensity: 0.5,
          valence: 0.0,
          arousal: 0.0,
          timestamp: DateTime.now(),
        );
        expect(stateMin.arousal, 0.0);

        final stateMax = EmotionState(
          primary: EmotionType.excited,
          intensity: 0.5,
          valence: 0.0,
          arousal: 1.0,
          timestamp: DateTime.now(),
        );
        expect(stateMax.arousal, 1.0);
      });

      test('throws ArgumentError when intensity is below 0.0', () {
        expect(
          () => EmotionState(
            primary: EmotionType.neutral,
            intensity: -0.1,
            valence: 0.0,
            arousal: 0.5,
            timestamp: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when intensity is above 1.0', () {
        expect(
          () => EmotionState(
            primary: EmotionType.neutral,
            intensity: 1.1,
            valence: 0.0,
            arousal: 0.5,
            timestamp: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when valence is below -1.0', () {
        expect(
          () => EmotionState(
            primary: EmotionType.sad,
            intensity: 0.5,
            valence: -1.1,
            arousal: 0.5,
            timestamp: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when valence is above 1.0', () {
        expect(
          () => EmotionState(
            primary: EmotionType.happy,
            intensity: 0.5,
            valence: 1.1,
            arousal: 0.5,
            timestamp: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when arousal is below 0.0', () {
        expect(
          () => EmotionState(
            primary: EmotionType.sleepy,
            intensity: 0.5,
            valence: 0.0,
            arousal: -0.1,
            timestamp: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when arousal is above 1.0', () {
        expect(
          () => EmotionState(
            primary: EmotionType.excited,
            intensity: 0.5,
            valence: 0.0,
            arousal: 1.1,
            timestamp: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('factory constructors', () {
      test('neutral() creates a valid neutral state', () {
        final state = EmotionState.neutral();

        expect(state.primary, EmotionType.neutral);
        expect(state.intensity, 0.5);
        expect(state.valence, 0.0);
        expect(state.arousal, 0.3);
      });
    });

    group('copyWith', () {
      test('creates copy with overridden values', () {
        final original = EmotionState(
          primary: EmotionType.neutral,
          intensity: 0.5,
          valence: 0.0,
          arousal: 0.3,
          timestamp: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith(
          primary: EmotionType.happy,
          intensity: 0.9,
          valence: 0.8,
        );

        expect(copy.primary, EmotionType.happy);
        expect(copy.intensity, 0.9);
        expect(copy.valence, 0.8);
        expect(copy.arousal, 0.3); // unchanged
        expect(copy.timestamp, DateTime(2024, 1, 1)); // unchanged
      });

      test('copyWith validates new values', () {
        final state = EmotionState.neutral();

        expect(
          () => state.copyWith(intensity: 2.0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        final timestamp = DateTime(2024, 1, 1);
        final a = EmotionState(
          primary: EmotionType.happy,
          intensity: 0.8,
          valence: 0.5,
          arousal: 0.6,
          timestamp: timestamp,
        );
        final b = EmotionState(
          primary: EmotionType.happy,
          intensity: 0.8,
          valence: 0.5,
          arousal: 0.6,
          timestamp: timestamp,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different states are not equal', () {
        final timestamp = DateTime(2024, 1, 1);
        final a = EmotionState(
          primary: EmotionType.happy,
          intensity: 0.8,
          valence: 0.5,
          arousal: 0.6,
          timestamp: timestamp,
        );
        final b = EmotionState(
          primary: EmotionType.sad,
          intensity: 0.8,
          valence: -0.5,
          arousal: 0.6,
          timestamp: timestamp,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('secondary emotion', () {
      test('secondary emotion is optional', () {
        final state = EmotionState(
          primary: EmotionType.happy,
          intensity: 0.5,
          valence: 0.5,
          arousal: 0.5,
          timestamp: DateTime.now(),
        );

        expect(state.secondary, isNull);
      });

      test('can set secondary emotion', () {
        final state = EmotionState(
          primary: EmotionType.happy,
          secondary: EmotionType.curious,
          intensity: 0.5,
          valence: 0.5,
          arousal: 0.5,
          timestamp: DateTime.now(),
        );

        expect(state.secondary, EmotionType.curious);
      });
    });
  });
}
