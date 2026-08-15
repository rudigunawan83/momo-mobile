import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../config/env_config.dart';
import '../storage/secure_storage_service.dart';

/// Providers untuk core services

/// Secure Storage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Token Notifier Provider - reactive token state dengan sync access
final tokenNotifierProvider =
    StateNotifierProvider<TokenNotifier, String?>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TokenNotifier(storage);
});

/// API Client Provider - uses token from TokenNotifier
final apiClientProvider = Provider<ApiClient>((ref) {
  final apiClient = ApiClient();

  apiClient.init(
    baseUrl: EnvConfig.apiBaseUrl,
    getToken: () {
      // Synchronous read dari TokenNotifier state (yang sudah di-cache)
      return ref.read(tokenNotifierProvider) ?? '';
    },
  );

  return apiClient;
});
