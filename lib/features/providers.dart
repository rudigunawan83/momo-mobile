/// Feature Providers — menyatukan semua Riverpod providers
/// Semua import di bagian atas (Dart requirement)

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core
import '../core/storage/secure_storage_service.dart';
import '../core/providers/core_providers.dart';
import '../core/models/base_models.dart';
import '../core/models/dto_models.dart';

// Auth
import 'auth/domain/repositories/auth_repository.dart';
import 'auth/data/repositories/auth_repository_impl.dart';
import 'auth/data/datasources/auth_remote_data_source.dart';
import 'auth/domain/usecases/auth_usecases.dart';
import 'auth/data/models/auth_models.dart';

// Profile
import 'profile/domain/repositories/user_repository.dart';
import 'profile/data/repositories/user_repository_impl.dart';
import 'profile/data/datasources/user_remote_data_source.dart';
import 'profile/domain/usecases/user_usecases.dart';

// Chat
import 'chat/domain/repositories/chat_repository.dart';
import 'chat/data/repositories/chat_repository_impl.dart';
import 'chat/data/datasources/chat_remote_data_source.dart';

// ===== AUTH PROVIDERS =====

/// Auth Remote Data Source Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient: apiClient);
});

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    secureStorage: secureStorage,
  );
});

/// Login UseCase Provider
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Logout UseCase Provider
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Refresh Token UseCase Provider
final refreshTokenUseCaseProvider = Provider<RefreshTokenUseCase>((ref) {
  return RefreshTokenUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Check Auth UseCase Provider
final checkAuthUseCaseProvider = Provider<CheckAuthUseCase>((ref) {
  return CheckAuthUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Auth State Notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<AuthResponse?>> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthUseCase checkAuthUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final TokenNotifier tokenNotifier;

  AuthStateNotifier({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkAuthUseCase,
    required this.refreshTokenUseCase,
    required this.tokenNotifier,
  }) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final isAuth = await checkAuthUseCase();
      if (isAuth) {
        // Authenticated — set dummy non-null response so isAuth=true
        state = AsyncValue.data(AuthResponse(
          accessToken: '',
          expiresIn: 0,
          user: AuthUserDto(id: '', name: '', nickname: ''),
        ));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await loginUseCase(email: email, password: password);
      result.map(
        (success) {
          tokenNotifier.setToken(success.accessToken);
          state = AsyncValue.data(success);
        },
        (failure) {
          // Keep error in state but don't throw — prevents unhandled exception crash
          state = AsyncValue.data(null);
          // Re-expose error via a separate mechanism if needed
          throw failure.exception;
        },
      );
    } catch (e, st) {
      state = AsyncValue.data(null); // Stay on login page, don't crash app
      rethrow; // Let the UI layer catch and show error message
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final result = await logoutUseCase();
    await tokenNotifier.clearToken();

    result.map(
      (_) => state = const AsyncValue.data(null),
      (_) => state = const AsyncValue.data(null), // Selalu berhasil di client
    );
  }

  Future<void> refreshToken(String refreshToken) async {
    final result = await refreshTokenUseCase(refreshToken: refreshToken);
    result.map(
      (success) {
        tokenNotifier.setToken(success.accessToken);
        state = AsyncValue.data(success);
      },
      (failure) {
        state = AsyncValue.error(failure.exception, StackTrace.current);
      },
    );
  }

  bool get isAuthenticated {
    return state.whenData((data) => data != null).value ?? false;
  }
}

/// Auth State Provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthResponse?>>((ref) {
  return AuthStateNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    checkAuthUseCase: ref.watch(checkAuthUseCaseProvider),
    refreshTokenUseCase: ref.watch(refreshTokenUseCaseProvider),
    tokenNotifier: ref.watch(tokenNotifierProvider.notifier),
  );
});

/// Is Authenticated Provider — safely handles loading/error states
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  // Use whenOrNull to avoid throwing on error state
  return authState.whenOrNull(data: (data) => data != null) ?? false;
});

// ===== USER PROVIDERS =====

/// User Remote Data Source Provider
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider));
});

/// User Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
      remoteDataSource: ref.watch(userRemoteDataSourceProvider));
});

/// Get Current User UseCase
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(repository: ref.watch(userRepositoryProvider));
});

/// Get XP Profile UseCase
final getXpProfileUseCaseProvider = Provider<GetXpProfileUseCase>((ref) {
  return GetXpProfileUseCase(repository: ref.watch(userRepositoryProvider));
});

/// Get Relationship UseCase
final getRelationshipUseCaseProvider =
    Provider<GetRelationshipUseCase>((ref) {
  return GetRelationshipUseCase(
      repository: ref.watch(userRepositoryProvider));
});

/// Get Greeting UseCase
final getGreetingUseCaseProvider = Provider<GetGreetingUseCase>((ref) {
  return GetGreetingUseCase(repository: ref.watch(userRepositoryProvider));
});

/// Current User Provider — returns null instead of throwing on error
final currentUserProvider = FutureProvider<UserProfileDto?>((ref) async {
  // Only fetch when authenticated
  final isAuth = ref.watch(isAuthenticatedProvider);
  if (!isAuth) return null;
  final useCase = ref.watch(getCurrentUserUseCaseProvider);
  final result = await useCase();
  return result.map(
    (data) => data,
    (_) => null, // silently return null on failure
  );
});

/// Current XP Provider — returns default on error
final currentXpProvider = FutureProvider<XpProfileDto?>((ref) async {
  final isAuth = ref.watch(isAuthenticatedProvider);
  if (!isAuth) return null;
  final useCase = ref.watch(getXpProfileUseCaseProvider);
  final result = await useCase();
  return result.map(
    (data) => data,
    (_) => null,
  );
});

/// Current Relationship Provider — returns default on error
final currentRelationshipProvider =
    FutureProvider<RelationshipDto?>((ref) async {
  final isAuth = ref.watch(isAuthenticatedProvider);
  if (!isAuth) return null;
  final useCase = ref.watch(getRelationshipUseCaseProvider);
  final result = await useCase();
  return result.map(
    (data) => data,
    (_) => null,
  );
});

/// Current Greeting Provider
final currentGreetingProvider = FutureProvider<String>((ref) async {
  final useCase = ref.watch(getGreetingUseCaseProvider);
  return await useCase();
});

// ===== CHAT PROVIDERS =====

/// Chat Remote Data Source Provider
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider));
});

/// Chat Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
      remoteDataSource: ref.watch(chatRemoteDataSourceProvider));
});

/// Current Conversation ID State
final currentConversationIdProvider = StateProvider<String?>((ref) => null);

/// Get Conversations Provider
final getConversationsProvider =
    FutureProvider<List<Conversation>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getConversations();
  return result.map(
    (data) => data,
    (failure) => throw failure.exception,
  );
});
