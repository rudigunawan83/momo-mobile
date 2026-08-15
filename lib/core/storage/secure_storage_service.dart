import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Secure Storage Service - untuk menyimpan data sensitif seperti token
class SecureStorageService {
  // Non-const instance (can't be const due to platform-specific options)
  final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Save token
  Future<void> saveToken(String token) async {
    await _storage.write(
      key: AppConstants.userTokenKey,
      value: token,
    );
  }

  /// Get token
  Future<String?> getToken() async {
    return await _storage.read(
      key: AppConstants.userTokenKey,
    );
  }

  /// Delete token
  Future<void> deleteToken() async {
    await _storage.delete(
      key: AppConstants.userTokenKey,
    );
  }

  /// Save user data (JSON string)
  Future<void> saveUserData(String jsonData) async {
    await _storage.write(
      key: AppConstants.userDataKey,
      value: jsonData,
    );
  }

  /// Get user data
  Future<String?> getUserData() async {
    return await _storage.read(
      key: AppConstants.userDataKey,
    );
  }

  /// Delete user data
  Future<void> deleteUserData() async {
    await _storage.delete(
      key: AppConstants.userDataKey,
    );
  }

  /// Logout - clear all secure storage
  Future<void> logout() async {
    await Future.wait([
      deleteToken(),
      deleteUserData(),
    ]);
  }

  /// Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

/// Token Notifier untuk reactive token state management
class TokenNotifier extends StateNotifier<String?> {
  final SecureStorageService _storage;

  TokenNotifier(this._storage) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.getToken();
    state = token;
  }

  Future<void> setToken(String token) async {
    await _storage.saveToken(token);
    state = token;
  }

  Future<void> clearToken() async {
    await _storage.deleteToken();
    state = null;
  }

  bool get isTokenValid => state != null && state!.isNotEmpty;
}
