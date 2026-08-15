/// Auth Remote Data Source - untuk API calls
import '../models/auth_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

abstract class AuthRemoteDataSource {
  /// Login dengan email dan password
  /// 
  /// Throws [NetworkException], [TimeoutException], [ServerException]
  Future<AuthResponse> login({
    required String email,
    required String password,
  });

  /// Logout
  Future<void> logout();

  /// Refresh access token
  /// 
  /// Throws [NetworkException], [UnauthorizedException]
  Future<AuthResponse> refreshToken({required String refreshToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );

      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      return AuthResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponse> refreshToken({required String refreshToken}) async {
    try {
      final request = RefreshTokenRequest(refreshToken: refreshToken);

      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: request.toJson(),
      );

      return AuthResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
