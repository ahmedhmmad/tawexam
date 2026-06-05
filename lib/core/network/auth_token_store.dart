import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';
import 'token_provider.dart';

class AuthTokenStore implements TokenProvider {
  const AuthTokenStore(this._storage, this._secureStorage);

  final LocalStorageService _storage;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readAccessToken() async {
    final secureToken = await _secureStorage.read(
      key: StorageKeys.secureAccessToken,
    );
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }
    return _storage.read<String>(StorageKeys.authBox, StorageKeys.accessToken);
  }

  @override
  Future<String?> readRefreshToken() async {
    final secureToken = await _secureStorage.read(
      key: StorageKeys.secureRefreshToken,
    );
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }
    return _storage.read<String>(StorageKeys.authBox, StorageKeys.refreshToken);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(
      StorageKeys.authBox,
      StorageKeys.accessToken,
      accessToken,
    );
    await _secureStorage.write(
      key: StorageKeys.secureAccessToken,
      value: accessToken,
    );
    if (refreshToken != null) {
      await _storage.write(
        StorageKeys.authBox,
        StorageKeys.refreshToken,
        refreshToken,
      );
      await _secureStorage.write(
        key: StorageKeys.secureRefreshToken,
        value: refreshToken,
      );
    }
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(StorageKeys.authBox, StorageKeys.accessToken);
    await _storage.delete(StorageKeys.authBox, StorageKeys.refreshToken);
    await _secureStorage.delete(key: StorageKeys.secureAccessToken);
    await _secureStorage.delete(key: StorageKeys.secureRefreshToken);
  }
}
