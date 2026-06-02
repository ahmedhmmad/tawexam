import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';
import 'token_provider.dart';

class AuthTokenStore implements TokenProvider {
  const AuthTokenStore(this._storage);

  final LocalStorageService _storage;

  @override
  Future<String?> readAccessToken() {
    return _storage.read<String>(StorageKeys.authBox, StorageKeys.accessToken);
  }

  @override
  Future<String?> readRefreshToken() {
    return _storage.read<String>(StorageKeys.authBox, StorageKeys.refreshToken);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(StorageKeys.authBox, StorageKeys.accessToken, accessToken);
    if (refreshToken != null) {
      await _storage.write(StorageKeys.authBox, StorageKeys.refreshToken, refreshToken);
    }
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(StorageKeys.authBox, StorageKeys.accessToken);
    await _storage.delete(StorageKeys.authBox, StorageKeys.refreshToken);
  }
}
