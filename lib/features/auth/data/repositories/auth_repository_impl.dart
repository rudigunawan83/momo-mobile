/// Auth Repository Implementation
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Simpan token ke secure storage
      await secureStorage.saveToken(response.accessToken);

      // Simpan user data
      await secureStorage.saveUserData(response.user.toJson().toString());

      return Success(response);
    } on UnauthorizedException catch (e) {
      return Failure(
        exception: e,
        message: 'Email atau password salah',
      );
    } on NetworkException catch (e) {
      return Failure(
        exception: e,
        message: 'Network error. Periksa koneksi internet kamu.',
      );
    } on TimeoutException catch (e) {
      return Failure(
        exception: e,
        message: 'Koneksi timeout. Coba lagi.',
      );
    } on ServerException catch (e) {
      return Failure(
        exception: e,
        message: 'Momo sedang mengalami gangguan. Coba lagi nanti.',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await remoteDataSource.logout();
      await secureStorage.logout();
      return Success(null);
    } on MomoException catch (e) {
      // Even jika API error, tetap clear local storage
      await secureStorage.logout();
      return Failure(
        exception: e,
        message: 'Logout successful',
      );
    } catch (e) {
      await secureStorage.logout();
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Logout berhasil',
      );
    }
  }

  @override
  Future<Result<AuthResponse>> refreshToken({required String refreshToken}) async {
    try {
      final response = await remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );

      // Update token
      await secureStorage.saveToken(response.accessToken);

      return Success(response);
    } on UnauthorizedException catch (e) {
      // Refresh token expired, need to login again
      await secureStorage.logout();
      return Failure(
        exception: e,
        message: 'Session expired. Silakan login kembali.',
      );
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal refresh token',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal refresh token',
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await secureStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.getToken();
  }
}
