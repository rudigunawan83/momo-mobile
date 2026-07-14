import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/services/rive_fallback_handler.dart';

void main() {
  group('RiveFallbackHandler', () {
    group('initial state', () {
      test('starts in rive mode', () {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => true,
        );

        expect(handler.currentMode, CharacterDisplayMode.rive);
        handler.dispose();
      });

      test('starts with zero reload attempts', () {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => true,
        );

        expect(handler.reloadAttempts, 0);
        handler.dispose();
      });

      test('is not permanently failed initially', () {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => true,
        );

        expect(handler.isPermanentlyFailed, false);
        handler.dispose();
      });

      test('is not reloading initially', () {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => true,
        );

        expect(handler.isReloading, false);
        handler.dispose();
      });
    });

    group('handleRiveException - immediate fallback', () {
      test('immediately switches to static mode on exception', () async {
        final modes = <CharacterDisplayMode>[];
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => true,
        );
        handler.modeStream.listen(modes.add);

        // Don't await — we just want to verify immediate mode switch.
        unawaited(handler.handleRiveException(Exception('Rive crash')));

        // Give microtask a chance to process.
        await Future<void>.delayed(Duration.zero);

        expect(handler.currentMode, CharacterDisplayMode.static);
        expect(modes, contains(CharacterDisplayMode.static));

        handler.dispose();
      });
    });

    group('handleRiveException - reload attempts', () {
      test('attempts reload up to 2 times with 3-second delay', () async {
        int reloadCallCount = 0;
        final handler = RiveFallbackHandler(
          reloadArtboard: () async {
            reloadCallCount++;
            return false; // Always fail
          },
        );

        await handler.handleRiveException(Exception('Rive crash'));

        // Should have attempted exactly 2 reloads.
        expect(reloadCallCount, 2);
        expect(handler.reloadAttempts, 2);

        handler.dispose();
      });

      test('switches back to rive mode on successful first reload', () async {
        final modes = <CharacterDisplayMode>[];
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => true, // Succeed on first attempt
        );
        handler.modeStream.listen(modes.add);

        await handler.handleRiveException(Exception('Rive crash'));

        // Allow stream events to propagate.
        await Future<void>.delayed(Duration.zero);

        expect(handler.currentMode, CharacterDisplayMode.rive);
        expect(handler.reloadAttempts, 1);
        expect(handler.isPermanentlyFailed, false);
        expect(modes, [CharacterDisplayMode.static, CharacterDisplayMode.rive]);

        handler.dispose();
      });

      test('switches back to rive mode on successful second reload', () async {
        int attempt = 0;
        final handler = RiveFallbackHandler(
          reloadArtboard: () async {
            attempt++;
            return attempt >= 2; // Fail first, succeed second
          },
        );

        await handler.handleRiveException(Exception('Rive crash'));

        expect(handler.currentMode, CharacterDisplayMode.rive);
        expect(handler.reloadAttempts, 2);
        expect(handler.isPermanentlyFailed, false);

        handler.dispose();
      });

      test('remains on static image permanently if all reloads fail', () async {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => false, // Always fail
        );

        await handler.handleRiveException(Exception('Rive crash'));

        expect(handler.currentMode, CharacterDisplayMode.static);
        expect(handler.reloadAttempts, 2);
        expect(handler.isPermanentlyFailed, true);

        handler.dispose();
      });

      test('remains on static if reload throws exception', () async {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => throw Exception('Load error'),
        );

        await handler.handleRiveException(Exception('Rive crash'));

        expect(handler.currentMode, CharacterDisplayMode.static);
        expect(handler.isPermanentlyFailed, true);

        handler.dispose();
      });
    });

    group('handleRiveException - idempotency', () {
      test('is no-op when already permanently failed', () async {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => false,
        );

        await handler.handleRiveException(Exception('first'));
        expect(handler.isPermanentlyFailed, true);

        // Second call should be no-op.
        await handler.handleRiveException(Exception('second'));
        expect(handler.reloadAttempts, 2); // Still from first round
        handler.dispose();
      });

      test('is no-op while already reloading', () async {
        int reloadCallCount = 0;
        final completer = Completer<bool>();
        final handler = RiveFallbackHandler(
          reloadArtboard: () {
            reloadCallCount++;
            return completer.future;
          },
        );

        // Start first exception handling (will block on reload).
        final future = handler.handleRiveException(Exception('first'));

        // Immediately try again — should be no-op since we're reloading.
        await handler.handleRiveException(Exception('second'));

        // Complete the reload.
        completer.complete(true);
        await future;

        // Only one reload call was made (from first exception).
        expect(reloadCallCount, 1);
        handler.dispose();
      });
    });

    group('reset', () {
      test('resets to rive mode after permanent failure', () async {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => false,
        );

        await handler.handleRiveException(Exception('crash'));
        expect(handler.isPermanentlyFailed, true);

        handler.reset();

        expect(handler.currentMode, CharacterDisplayMode.rive);
        expect(handler.reloadAttempts, 0);
        expect(handler.isPermanentlyFailed, false);
        expect(handler.isReloading, false);

        handler.dispose();
      });

      test('allows new exception handling after reset', () async {
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => true,
        );

        // First failure cycle.
        await handler.handleRiveException(Exception('crash'));
        handler.reset();

        // Second failure cycle should work.
        await handler.handleRiveException(Exception('crash again'));
        expect(handler.currentMode, CharacterDisplayMode.rive);

        handler.dispose();
      });
    });

    group('modeStream', () {
      test('emits mode changes to multiple listeners', () async {
        final modes1 = <CharacterDisplayMode>[];
        final modes2 = <CharacterDisplayMode>[];
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => true,
        );
        handler.modeStream.listen(modes1.add);
        handler.modeStream.listen(modes2.add);

        await handler.handleRiveException(Exception('crash'));

        // Allow stream events to propagate.
        await Future<void>.delayed(Duration.zero);

        expect(modes1, [CharacterDisplayMode.static, CharacterDisplayMode.rive]);
        expect(modes2, [CharacterDisplayMode.static, CharacterDisplayMode.rive]);

        handler.dispose();
      });

      test('does not emit duplicate modes', () async {
        final modes = <CharacterDisplayMode>[];
        final handler = RiveFallbackHandler(
          reloadArtboard: () async => false,
        );
        handler.modeStream.listen(modes.add);

        await handler.handleRiveException(Exception('crash'));

        // Should only emit static once (not on each failed reload attempt).
        expect(modes, [CharacterDisplayMode.static]);

        handler.dispose();
      });
    });

    group('constants', () {
      test('maxReloadAttempts is 2', () {
        expect(RiveFallbackHandler.maxReloadAttempts, 2);
      });

      test('reloadDelay is 3 seconds', () {
        expect(
          RiveFallbackHandler.reloadDelay,
          const Duration(seconds: 3),
        );
      });
    });
  });
}
