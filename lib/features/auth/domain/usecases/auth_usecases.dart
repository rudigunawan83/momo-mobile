/// Use Cases untuk Auth

import '../repositories/auth_repository.dart';
import '../../../../core/errors/result.dart';
import '../../data/models/auth_models.dart';

/// Login UseCase
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<Result<AuthResponse>> call({
    required String email,
    required String password,
  }) {
    return repository.login(email: email, password: password);
  }
}

/// Logout UseCase
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase({required this.repository});

  Future<Result<void>> call() {
    return repository.logout();
  }
}

/// Refresh Token UseCase
class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase({required this.repository});

  Future<Result<AuthResponse>> call({required String refreshToken}) {
    return repository.refreshToken(refreshToken: refreshToken);
  }
}

/// Check Authentication UseCase
class CheckAuthUseCase {
  final AuthRepository repository;

  CheckAuthUseCase({required this.repository});

  Future<bool> call() {
    return repository.isAuthenticated();
  }
}
