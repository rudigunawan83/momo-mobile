import 'dart:async';

/// Result of a token refresh attempt.
enum TokenRefreshResult {
  /// Token was refreshed successfully — session continues uninterrupted.
  success,

  /// Refresh failed — user must re-authenticate.
  failure,
}

/// Callback for performing the actual token refresh via Supabase.
///
/// Returns `true` if the refresh succeeded, `false` otherwise.
typedef TokenRefresher = Future<bool> Function();

/// Callback for retrieving the current access token.
typedef TokenProvider = Future<String?> Function();

/// Callback for persisting unsent message drafts to local storage.
typedef DraftPersister = Future<void> Function(List<String> drafts);

/// Callback for navigating to the login screen.
typedef LoginRedirector = void Function();

/// Manages silent token refresh and handles refresh failures.
///
/// Behavior per Requirements 10.4 and 10.5:
/// - When the authentication token expires during an active session,
///   attempts a silent refresh using the stored refresh token without
///   interrupting the user's current interaction.
/// - If the silent refresh fails (expired or invalid refresh token),
///   redirects to login and preserves unsent message drafts in local storage.
///
/// Requirements: 10.4, 10.5
class TokenRefreshService {
  final TokenRefresher _refreshToken;
  final DraftPersister _persistDrafts;
  final LoginRedirector _redirectToLogin;

  bool _isRefreshing = false;
  Completer<TokenRefreshResult>? _refreshCompleter;

  final StreamController<TokenRefreshEvent> _eventController =
      StreamController<TokenRefreshEvent>.broadcast();

  /// Creates a [TokenRefreshService].
  ///
  /// [refreshToken] performs the actual token refresh (e.g., via Supabase).
  /// [persistDrafts] saves unsent drafts to local storage on failure.
  /// [redirectToLogin] navigates the user to the login screen on failure.
  TokenRefreshService({
    required TokenRefresher refreshToken,
    required DraftPersister persistDrafts,
    required LoginRedirector redirectToLogin,
  })  : _refreshToken = refreshToken,
        _persistDrafts = persistDrafts,
        _redirectToLogin = redirectToLogin;

  /// Whether a token refresh is currently in progress.
  bool get isRefreshing => _isRefreshing;

  /// Stream of token refresh events for observability.
  Stream<TokenRefreshEvent> get eventStream => _eventController.stream;

  /// Attempts to silently refresh the authentication token.
  ///
  /// If a refresh is already in progress, returns the result of the
  /// ongoing refresh (coalesces concurrent calls).
  ///
  /// Returns [TokenRefreshResult.success] if the token was refreshed,
  /// or [TokenRefreshResult.failure] if it could not be refreshed.
  ///
  /// On failure, [unsentDrafts] are persisted to local storage and
  /// the user is redirected to the login screen.
  Future<TokenRefreshResult> attemptRefresh({
    List<String> unsentDrafts = const [],
  }) async {
    // Coalesce concurrent refresh requests
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<TokenRefreshResult>();
    _emitEvent(TokenRefreshEvent.refreshStarted);

    try {
      final success = await _refreshToken();

      if (success) {
        _emitEvent(TokenRefreshEvent.refreshSucceeded);
        _completeRefresh(TokenRefreshResult.success);
        return TokenRefreshResult.success;
      } else {
        await _handleRefreshFailure(unsentDrafts);
        _completeRefresh(TokenRefreshResult.failure);
        return TokenRefreshResult.failure;
      }
    } catch (_) {
      await _handleRefreshFailure(unsentDrafts);
      _completeRefresh(TokenRefreshResult.failure);
      return TokenRefreshResult.failure;
    }
  }

  /// Disposes resources held by this service.
  void dispose() {
    _eventController.close();
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _handleRefreshFailure(List<String> unsentDrafts) async {
    _emitEvent(TokenRefreshEvent.refreshFailed);

    // Preserve unsent drafts in local storage
    if (unsentDrafts.isNotEmpty) {
      try {
        await _persistDrafts(unsentDrafts);
        _emitEvent(TokenRefreshEvent.draftsPersisted);
      } catch (_) {
        // Best effort — don't block login redirect if draft persistence fails
      }
    }

    // Redirect to login screen
    _redirectToLogin();
    _emitEvent(TokenRefreshEvent.redirectedToLogin);
  }

  void _completeRefresh(TokenRefreshResult result) {
    _isRefreshing = false;
    _refreshCompleter?.complete(result);
    _refreshCompleter = null;
  }

  void _emitEvent(TokenRefreshEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
}

/// Events emitted during the token refresh lifecycle.
enum TokenRefreshEvent {
  /// A token refresh attempt has started.
  refreshStarted,

  /// The token was refreshed successfully.
  refreshSucceeded,

  /// The token refresh failed.
  refreshFailed,

  /// Unsent message drafts were persisted to local storage.
  draftsPersisted,

  /// The user was redirected to the login screen.
  redirectedToLogin,
}
