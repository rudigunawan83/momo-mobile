import 'dart:async';

import '../domain/entities/character_state.dart';
import 'rive_fallback_handler.dart';

/// Callback type for loading a Rive artboard from file/asset.
///
/// Returns `true` if loading succeeded, throws on failure.
typedef RiveArtboardLoader = Future<bool> Function();

/// Callback type for triggering a Rive state machine input.
///
/// Takes the target [CharacterState] name and applies it to the active
/// artboard's state machine. Throws if the artboard is in a bad state.
typedef RiveStateApplier = Future<void> Function(String stateName);

/// Controller that wraps Rive runtime interactions and delegates failures
/// to [RiveFallbackHandler].
///
/// This is the integration layer between the Character Engine's logical
/// state machine and the actual Rive runtime. It catches all Rive runtime
/// exceptions during:
/// - Initial artboard loading
/// - State machine input application
/// - Animation playback
///
/// On any exception, it immediately delegates to [RiveFallbackHandler] which:
/// 1. Switches to static character image immediately
/// 2. Attempts artboard reload up to 2 times with 3-second delays
/// 3. Remains on static image permanently if all reloads fail
///
/// Requirement 10.8: IF the Rive animation engine throws an exception,
/// THEN the Character_Engine SHALL fall back to a static character image,
/// attempt to reload the Rive artboard up to 2 times with a 3-second delay
/// between attempts, and remain on the static image if all reload attempts fail.
class RiveCharacterController {
  final RiveFallbackHandler _fallbackHandler;
  final RiveStateApplier _stateApplier;

  bool _isArtboardReady = false;

  /// Creates a [RiveCharacterController].
  ///
  /// [fallbackHandler] manages the rive/static mode transitions and retry logic.
  /// [stateApplier] applies state machine inputs to the Rive artboard.
  RiveCharacterController({
    required this._fallbackHandler,
    required this._stateApplier,
  });

  /// The fallback handler managing display mode.
  RiveFallbackHandler get fallbackHandler => _fallbackHandler;

  /// Whether the Rive artboard is ready for state machine input.
  bool get isArtboardReady => _isArtboardReady;

  /// Whether the controller is operating in fallback (static) mode.
  bool get isInFallbackMode =>
      _fallbackHandler.currentMode == CharacterDisplayMode.static;

  /// Marks the artboard as ready after successful initialization.
  ///
  /// Call this after the Rive file has been loaded and the artboard
  /// and state machine controller are initialized successfully.
  void markArtboardReady() {
    _isArtboardReady = true;
  }

  /// Applies a character state to the Rive state machine.
  ///
  /// Catches any Rive runtime exceptions and delegates to the fallback
  /// handler. If already in fallback mode or artboard isn't ready,
  /// this is a no-op (the CharacterDisplayWidget shows the static image).
  ///
  /// Returns `true` if the state was applied successfully, `false` if
  /// it was skipped or failed (and fallback was triggered).
  Future<bool> applyState(CharacterState state) async {
    if (!_isArtboardReady || isInFallbackMode) {
      return false;
    }

    try {
      await _stateApplier(state.name);
      return true;
    } catch (e) {
      await _handleRiveFailure(e);
      return false;
    }
  }

  /// Wraps any Rive runtime operation with exception catching.
  ///
  /// Use this for custom Rive operations beyond state application
  /// (e.g., eye-tracking SMI updates, lip-sync triggers).
  ///
  /// Returns `true` if the operation succeeded, `false` if it failed
  /// and fallback was triggered.
  Future<bool> safeRiveOperation(Future<void> Function() operation) async {
    if (!_isArtboardReady || isInFallbackMode) {
      return false;
    }

    try {
      await operation();
      return true;
    } catch (e) {
      await _handleRiveFailure(e);
      return false;
    }
  }

  /// Wraps a synchronous Rive operation with exception catching.
  ///
  /// Use this for sync operations like setting SMI input values.
  ///
  /// Returns `true` if the operation succeeded, `false` if it failed.
  bool safeRiveSync(void Function() operation) {
    if (!_isArtboardReady || isInFallbackMode) {
      return false;
    }

    try {
      operation();
      return true;
    } catch (e) {
      // Fire-and-forget the async handler — the mode switch is immediate
      // inside handleRiveException before the async reload starts.
      _handleRiveFailure(e);
      return false;
    }
  }

  /// Called when the fallback handler successfully reloads the artboard.
  ///
  /// Listens to [RiveFallbackHandler.modeStream] — when mode switches back
  /// to [CharacterDisplayMode.rive], this marks the artboard ready again.
  void onArtboardReloaded() {
    _isArtboardReady = true;
  }

  /// Called when the artboard becomes unavailable (e.g., fallback triggered).
  void onArtboardLost() {
    _isArtboardReady = false;
  }

  /// Disposes of resources.
  void dispose() {
    // RiveFallbackHandler is disposed separately (shared ownership).
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  /// Delegates the Rive failure to the fallback handler and marks the
  /// artboard as unavailable.
  Future<void> _handleRiveFailure(Object exception) async {
    _isArtboardReady = false;
    await _fallbackHandler.handleRiveException(exception);
  }
}
