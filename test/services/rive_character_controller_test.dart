import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/domain/entities/character_state.dart';
import 'package:momo_app/services/rive_character_controller.dart';
import 'package:momo_app/services/rive_fallback_handler.dart';

void main() {
  group('RiveCharacterController', () {
    late RiveFallbackHandler fallbackHandler;
    late List<String> appliedStates;
    late RiveCharacterController controller;

    setUp(() {
      appliedStates = [];
      fallbackHandler = RiveFallbackHandler(
        reloadArtboard: () async => true,
      );
      controller = RiveCharacterController(
        fallbackHandler: fallbackHandler,
        stateApplier: (stateName) async {
          appliedStates.add(stateName);
        },
      );
    });

    tearDown(() {
      controller.dispose();
      fallbackHandler.dispose();
    });

    group('initial state', () {
      test('artboard is not ready initially', () {
        expect(controller.isArtboardReady, false);
      });

      test('is not in fallback mode initially (handler starts in rive mode)', () {
        expect(controller.isInFallbackMode, false);
      });
    });

    group('markArtboardReady', () {
      test('marks artboard as ready', () {
        controller.markArtboardReady();
        expect(controller.isArtboardReady, true);
      });
    });

    group('applyState - success', () {
      test('applies state when artboard is ready', () async {
        controller.markArtboardReady();

        final result = await controller.applyState(CharacterState.happy);

        expect(result, true);
        expect(appliedStates, ['happy']);
      });

      test('applies multiple states sequentially', () async {
        controller.markArtboardReady();

        await controller.applyState(CharacterState.happy);
        await controller.applyState(CharacterState.thinking);
        await controller.applyState(CharacterState.idle);

        expect(appliedStates, ['happy', 'thinking', 'idle']);
      });
    });

    group('applyState - skipped conditions', () {
      test('returns false when artboard is not ready', () async {
        final result = await controller.applyState(CharacterState.happy);

        expect(result, false);
        expect(appliedStates, isEmpty);
      });

      test('returns false when in fallback mode', () async {
        controller.markArtboardReady();

        // Trigger fallback by causing an exception.
        await controller.applyState(CharacterState.happy);
        appliedStates.clear();

        // Force into fallback mode.
        await fallbackHandler.handleRiveException(Exception('crash'));

        // Now try to apply — should be skipped.
        // Need a handler that fails so we stay in static mode.
        final failHandler = RiveFallbackHandler(
          reloadArtboard: () async => false,
        );
        final failController = RiveCharacterController(
          fallbackHandler: failHandler,
          stateApplier: (s) async => appliedStates.add(s),
        );
        failController.markArtboardReady();

        await failHandler.handleRiveException(Exception('crash'));
        final result = await failController.applyState(CharacterState.happy);

        expect(result, false);

        failController.dispose();
        failHandler.dispose();
      });
    });

    group('applyState - exception handling (Requirement 10.8)', () {
      test('catches Rive exception and triggers fallback', () async {
        final failHandler = RiveFallbackHandler(
          reloadArtboard: () async => false,
        );
        final failController = RiveCharacterController(
          fallbackHandler: failHandler,
          stateApplier: (s) async => throw Exception('Rive artboard error'),
        );
        failController.markArtboardReady();

        final result = await failController.applyState(CharacterState.happy);

        expect(result, false);
        expect(failController.isArtboardReady, false);
        expect(failHandler.currentMode, CharacterDisplayMode.static);
        expect(failHandler.isPermanentlyFailed, true);

        failController.dispose();
        failHandler.dispose();
      });

      test('falls back to static then recovers on successful reload', () async {
        final modes = <CharacterDisplayMode>[];
        final reloadHandler = RiveFallbackHandler(
          reloadArtboard: () async => true, // Reload succeeds
        );
        reloadHandler.modeStream.listen(modes.add);

        final errorController = RiveCharacterController(
          fallbackHandler: reloadHandler,
          stateApplier: (s) async => throw Exception('Rive crash'),
        );
        errorController.markArtboardReady();

        await errorController.applyState(CharacterState.happy);

        // Allow stream events to propagate.
        await Future<void>.delayed(Duration.zero);

        // After successful reload, mode should be back to rive.
        expect(reloadHandler.currentMode, CharacterDisplayMode.rive);
        expect(modes, [CharacterDisplayMode.static, CharacterDisplayMode.rive]);

        errorController.dispose();
        reloadHandler.dispose();
      });
    });

    group('safeRiveOperation', () {
      test('executes operation successfully when artboard is ready', () async {
        controller.markArtboardReady();
        var executed = false;

        final result = await controller.safeRiveOperation(() async {
          executed = true;
        });

        expect(result, true);
        expect(executed, true);
      });

      test('returns false when artboard is not ready', () async {
        var executed = false;

        final result = await controller.safeRiveOperation(() async {
          executed = true;
        });

        expect(result, false);
        expect(executed, false);
      });

      test('catches exception and triggers fallback', () async {
        final failHandler = RiveFallbackHandler(
          reloadArtboard: () async => false,
        );
        final failController = RiveCharacterController(
          fallbackHandler: failHandler,
          stateApplier: (s) async {},
        );
        failController.markArtboardReady();

        final result = await failController.safeRiveOperation(() async {
          throw StateError('Rive state machine error');
        });

        expect(result, false);
        expect(failController.isArtboardReady, false);
        expect(failHandler.currentMode, CharacterDisplayMode.static);

        failController.dispose();
        failHandler.dispose();
      });
    });

    group('safeRiveSync', () {
      test('executes sync operation when artboard is ready', () {
        controller.markArtboardReady();
        var executed = false;

        final result = controller.safeRiveSync(() {
          executed = true;
        });

        expect(result, true);
        expect(executed, true);
      });

      test('returns false when artboard is not ready', () {
        var executed = false;

        final result = controller.safeRiveSync(() {
          executed = true;
        });

        expect(result, false);
        expect(executed, false);
      });

      test('catches sync exception and triggers fallback', () {
        final failHandler = RiveFallbackHandler(
          reloadArtboard: () async => false,
        );
        final failController = RiveCharacterController(
          fallbackHandler: failHandler,
          stateApplier: (s) async {},
        );
        failController.markArtboardReady();

        final result = failController.safeRiveSync(() {
          throw Exception('SMI input error');
        });

        expect(result, false);
        expect(failController.isArtboardReady, false);

        failController.dispose();
        failHandler.dispose();
      });
    });

    group('onArtboardReloaded / onArtboardLost', () {
      test('onArtboardReloaded marks artboard as ready', () {
        expect(controller.isArtboardReady, false);
        controller.onArtboardReloaded();
        expect(controller.isArtboardReady, true);
      });

      test('onArtboardLost marks artboard as not ready', () {
        controller.markArtboardReady();
        expect(controller.isArtboardReady, true);

        controller.onArtboardLost();
        expect(controller.isArtboardReady, false);
      });
    });

    group('fallbackHandler access', () {
      test('exposes the fallback handler', () {
        expect(controller.fallbackHandler, same(fallbackHandler));
      });
    });
  });
}
