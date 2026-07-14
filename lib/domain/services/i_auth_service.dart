/// Interface for authentication service (Supabase Auth).
///
/// Used during app startup to validate the current session and determine
/// whether the user should proceed to the companion experience or be
/// redirected to the authentication flow.
///
/// Requirements: 12.1, 12.4
abstract class IAuthService {
  /// Validates the current session.
  ///
  /// Returns `true` if the session is valid and the user is authenticated.
  /// Returns `false` if the session has expired or is invalid.
  Future<bool> validateSession();

  /// Returns the authenticated user's ID, or `null` if not authenticated.
  Future<String?> getCurrentUserId();
}
