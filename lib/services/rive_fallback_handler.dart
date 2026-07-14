import 'dart:async';

/// Represents the current display mode for the character.
enum CharacterDisplayMode {
  /// Rive animation is active and rendering.
  rive,

  /// Static fallback image is being displayed.
  static,
}

/// Handles Rive animation runtime failures by falling back to a static
/// character image and attempting to reload the Rive artboard.
///
/// Behavior per Requirement 10.8:
/// - On Rive exception: immediately show static character image.
/// - Attempt to reload the Rive artboard up to 2 times with a 3-second delay
///   between attempts.
/// - Remain on static image permanently (until app restart) if all reload
///   attempts fail.
///
/// Exposes [modeStream] for reactive UI updates and [reloadAttempts] for
/// observability.
class RiveFallbackHandler {
  /// Maximum number of reload attempts before giving up.
  static const int maxReloadAttempts = 2;

  /// Delay between reload attempts.
  static const Duration reloadDelay = Duration(seconds: 3);

  /// Callback that performs the actual Rive artboard reload.
  ///
  /// Returns `true` if reload succeeded, `false` otherwise.
  /// This will be wired to the actual Rive file loading later.
  final Future<bool> Function() _reloadArtboard;

  // --- State ---

  CharacterDisplayMode _currentMode = CharacterDisplayMode.rive;
  int _reloadAttempts = 0;
  bool _permanentlyFailed = false;
  bool _isReloading = false;

  // --- Stream ---

  final StreamController<CharacterDisplayMode> _modeController =
      StreamController<CharacterDisplayMode>.broadcast();

  /// Creates a [RiveFallbackHandler] with the given artboard reload callback.
  RiveFallbackHandler({required this._reloadArtboard});

  /// The current display mode (rive or static).
  CharacterDisplayMode get currentMode => _currentMode;

  /// Stream of display mode changes.
  Stream<CharacterDisplayMode> get modeStream => _modeController.stream;

  /// The number of reload attempts made so far.
  int get reloadAttempts => _reloadAttempts;

  /// Whether the handler has permanently failed and will not attempt
  /// further reloads until app restart.
  bool get isPermanentlyFailed => _permanentlyFailed;

  /// Whether a reload is currently in progress.
  bool get isReloading => _isReloading;

  /// Called when a Rive runtime exception is caught.
  ///
  /// Immediately switches to static mode and begins the reload process.
  /// If already permanently failed or currently reloading, this is a no-op.
  Future<void> handleRiveException(Object exception) async {
    if (_permanentlyFailed || _isReloading) return;

    // Immediately fall back to static image.
    _setMode(CharacterDisplayMode.static);

    // Attempt reload.
    await _attemptReload();
  }

  /// Resets the handler state. Useful for testing or manual recovery.
  ///
  /// After reset, the handler will be in rive mode with zero attempts.
  void reset() {
    _reloadAttempts = 0;
    _permanentlyFailed = false;
    _isReloading = false;
    _setMode(CharacterDisplayMode.rive);
  }

  /// Disposes of resources held by the handler.
  void dispose() {
    _modeController.close();
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  /// Attempts to reload the Rive artboard up to [maxReloadAttempts] times
  /// with [reloadDelay] between attempts.
  Future<void> _attemptReload() async {
    _isReloading = true;
    _reloadAttempts = 0;

    for (var attempt = 0; attempt < maxReloadAttempts; attempt++) {
      _reloadAttempts = attempt + 1;

      // Wait before attempting reload.
      await Future<void>.delayed(reloadDelay);

      // If disposed during wait, bail out.
      if (_modeController.isClosed) {
        _isReloading = false;
        return;
      }

      try {
        final success = await _reloadArtboard();
        if (success) {
          // Reload succeeded — switch back to Rive mode.
          _isReloading = false;
          _setMode(CharacterDisplayMode.rive);
          return;
        }
      } catch (_) {
        // Reload threw an exception — treat as failure, continue to next attempt.
      }
    }

    // All attempts exhausted — remain on static image permanently.
    _isReloading = false;
    _permanentlyFailed = true;
  }

  void _setMode(CharacterDisplayMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    if (!_modeController.isClosed) {
      _modeController.add(mode);
    }
  }
}
