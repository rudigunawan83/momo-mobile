import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/domain/engines/character_engine.dart';
import 'package:momo_app/domain/engines/character_engine_error.dart';
import 'package:momo_app/domain/entities/character_state.dart';

void main() {
  group('CharacterEngine', () {
    late CharacterEngine engine;

    setUp(() {
      engine = CharacterEngine();
    });

    tearDown(() {
      engine.dispose();
    });

    group('initialization', () {
      test('starts in idle state by default', () {
        expect(engine.currentState, CharacterState.idle);
      });

      test('can be initialized with a custom state', () {
        final customEngine = CharacterEngine(initialState: CharacterState.happy);
        expect(customEngine.currentState, CharacterState.happy);
        customEngine.dispose();
      });

      test('idle loop is not active initially', () {
        expect(engine.isIdleLoopActive, false);
      });
    });

    group('setState - valid transitions', () {
      test('transitions from idle to thinking', () async {
        final states = <CharacterState>[];
        engine.stateStream.listen(states.add);

        engine.setState(CharacterState.thinking);

        // Wait for the 500ms transition to complete.
        await Future<void>.delayed(
          const Duration(milliseconds: 600),
        );

        expect(engine.currentState, CharacterState.thinking);
        expect(states, [CharacterState.thinking]);
      });

      test('transitions from idle to happy', () async {
        final states = <CharacterState>[];
        engine.stateStream.listen(states.add);

        engine.setState(CharacterState.happy);

        await Future<void>.delayed(
          const Duration(milliseconds: 600),
        );

        expect(engine.currentState, CharacterState.happy);
        expect(states, [CharacterState.happy]);
      });

      test('can transition through multiple states sequentially', () async {
        final states = <CharacterState>[];
        engine.stateStream.listen(states.add);

        engine.setState(CharacterState.thinking);
        await Future<void>.delayed(const Duration(milliseconds: 600));

        engine.setState(CharacterState.happy);
        await Future<void>.delayed(const Duration(milliseconds: 600));

        engine.setState(CharacterState.idle);
        await Future<void>.delayed(const Duration(milliseconds: 600));

        expect(states, [
          CharacterState.thinking,
          CharacterState.happy,
          CharacterState.idle,
        ]);
        expect(engine.currentState, CharacterState.idle);
      });

      test('transitions to all valid states from idle', () async {
        for (final target in CharacterState.values) {
          if (target == CharacterState.idle) continue;

          final testEngine = CharacterEngine();
          final states = <CharacterState>[];
          testEngine.stateStream.listen(states.add);

          testEngine.setState(target);
          await Future<void>.delayed(const Duration(milliseconds: 600));

          expect(testEngine.currentState, target,
              reason: 'Failed transitioning to $target');
          expect(states.last, target);

          testEngine.dispose();
        }
      });
    });

    group('setState - same state (no-op)', () {
      test('setting current state is a no-op', () async {
        final states = <CharacterState>[];
        final errors = <CharacterEngineError>[];
        engine.stateStream.listen(states.add);
        engine.errorStream.listen(errors.add);

        engine.setState(CharacterState.idle); // same as current

        await Future<void>.delayed(const Duration(milliseconds: 600));

        expect(states, isEmpty);
        expect(errors, isEmpty);
        expect(engine.currentState, CharacterState.idle);
      });
    });

    group('setState - transition timing', () {
      test('state does not change immediately (500ms interpolation)', () {
        engine.setState(CharacterState.happy);

        // Immediately after calling setState, state should still be idle
        // (transition in progress).
        expect(engine.currentState, CharacterState.idle);
      });

      test('state changes after transition duration', () async {
        engine.setState(CharacterState.happy);

        await Future<void>.delayed(const Duration(milliseconds: 550));

        expect(engine.currentState, CharacterState.happy);
      });

      test('new setState cancels in-progress transition', () async {
        final states = <CharacterState>[];
        engine.stateStream.listen(states.add);

        engine.setState(CharacterState.happy);
        // Before the 500ms transition completes, request another transition.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        engine.setState(CharacterState.sad);

        // Wait for the second transition to complete.
        await Future<void>.delayed(const Duration(milliseconds: 600));

        // Only the final state should be emitted (first was cancelled).
        expect(engine.currentState, CharacterState.sad);
        expect(states, [CharacterState.sad]);
      });
    });

    group('stateStream', () {
      test('emits state changes to all listeners', () async {
        final states1 = <CharacterState>[];
        final states2 = <CharacterState>[];
        engine.stateStream.listen(states1.add);
        engine.stateStream.listen(states2.add);

        engine.setState(CharacterState.excited);
        await Future<void>.delayed(const Duration(milliseconds: 600));

        expect(states1, [CharacterState.excited]);
        expect(states2, [CharacterState.excited]);
      });
    });

    group('errorStream', () {
      test('does not emit errors for valid transitions', () async {
        final errors = <CharacterEngineError>[];
        engine.errorStream.listen(errors.add);

        engine.setState(CharacterState.happy);
        await Future<void>.delayed(const Duration(milliseconds: 600));

        expect(errors, isEmpty);
      });
    });

    group('idle loop', () {
      test('activates after 5 seconds of no interaction', () async {
        expect(engine.isIdleLoopActive, false);

        // Wait slightly more than 5 seconds.
        await Future<void>.delayed(const Duration(milliseconds: 5200));

        expect(engine.isIdleLoopActive, true);
      });

      test('resets idle timer on setState', () async {
        // Wait 4 seconds, then trigger a state change.
        await Future<void>.delayed(const Duration(milliseconds: 4000));
        engine.setState(CharacterState.happy);

        // Wait 3 more seconds — total 7s from start but only 3s from last interaction.
        await Future<void>.delayed(const Duration(milliseconds: 3000));

        expect(engine.isIdleLoopActive, false);
      });

      test('resets idle timer on eye tracking update', () async {
        await Future<void>.delayed(const Duration(milliseconds: 4000));
        engine.setEyeTrackingTarget(const Offset(100, 200));

        await Future<void>.delayed(const Duration(milliseconds: 3000));

        expect(engine.isIdleLoopActive, false);
      });

      test('startIdleLoop can be called manually', () {
        engine.startIdleLoop();
        expect(engine.isIdleLoopActive, true);
      });

      test('startIdleLoop is idempotent', () {
        engine.startIdleLoop();
        engine.startIdleLoop();
        expect(engine.isIdleLoopActive, true);
      });

      test('idle loop deactivates on setState', () async {
        engine.startIdleLoop();
        expect(engine.isIdleLoopActive, true);

        engine.setState(CharacterState.happy);
        expect(engine.isIdleLoopActive, false);
      });
    });

    group('eye tracking', () {
      test('updates eye tracking target', () {
        engine.setEyeTrackingTarget(const Offset(150, 300));
        expect(engine.eyeTrackingTarget, const Offset(150, 300));
      });

      test('updates target to new position', () {
        engine.setEyeTrackingTarget(const Offset(100, 200));
        engine.setEyeTrackingTarget(const Offset(250, 400));
        expect(engine.eyeTrackingTarget, const Offset(250, 400));
      });

      test('initial target is Offset.zero', () {
        expect(engine.eyeTrackingTarget, Offset.zero);
      });
    });

    group('stopAllAnimations', () {
      test('stops idle loop', () {
        engine.startIdleLoop();
        expect(engine.isIdleLoopActive, true);

        engine.stopAllAnimations();
        expect(engine.isIdleLoopActive, false);
      });

      test('cancels in-progress transition', () async {
        final states = <CharacterState>[];
        engine.stateStream.listen(states.add);

        engine.setState(CharacterState.happy);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        engine.stopAllAnimations();

        await Future<void>.delayed(const Duration(milliseconds: 600));

        // Transition was cancelled, state remains idle.
        expect(engine.currentState, CharacterState.idle);
        expect(states, isEmpty);
      });
    });

    group('dispose', () {
      test('throws StateError after dispose', () {
        engine.dispose();

        expect(
          () => engine.setState(CharacterState.happy),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError on setEyeTrackingTarget after dispose', () {
        engine.dispose();

        expect(
          () => engine.setEyeTrackingTarget(const Offset(10, 20)),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError on startIdleLoop after dispose', () {
        engine.dispose();

        expect(
          () => engine.startIdleLoop(),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError on stopAllAnimations after dispose', () {
        engine.dispose();

        expect(
          () => engine.stopAllAnimations(),
          throwsA(isA<StateError>()),
        );
      });

      test('dispose is idempotent', () {
        engine.dispose();
        // Second dispose should not throw.
        expect(() => engine.dispose(), returnsNormally);
      });
    });
  });
}
