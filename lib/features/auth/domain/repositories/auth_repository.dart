/// Auth Repository - interface
import '../../../../core/errors/result.dart';
import '../../data/models/auth_models.dart';

abstract class AuthRepository {
  /// Login dengan email dan password
  /// 
  /// Returns [Success<AuthResponse>] dengan token dan user data
  /// Returns [Failure] dengan error message
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
  });

  /// Logout
  Future<Result<void>> logout();

  /// Refresh access token
  /// 
  /// [refreshToken] - Refresh token dari login response
  Future<Result<AuthResponse>> refreshToken({required String refreshToken});

  /// Get current auth status
  Future<bool> isAuthenticated();

  /// Get current token
  Future<String?> getToken();
}
