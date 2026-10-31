import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';

/// Secure persistence of InfluxDB API tokens using platform keystore/keychain.
class SecureTokenStore {
  final FlutterSecureStorage _storage;

  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              groupId: StorageKeys.appGroupId,
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  AndroidOptions get _androidOptions =>
      const AndroidOptions(encryptedSharedPreferences: true);

  IOSOptions get _iosOptions => const IOSOptions(
    groupId: StorageKeys.appGroupId,
    accessibility: KeychainAccessibility.first_unlock,
  );

  /// Saves the secret token for the given [connectionId].
  Future<void> saveToken(String connectionId, String token) async {
    try {
      await _storage.write(
        key: StorageKeys.tokenKey(connectionId),
        value: token,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {}
  }

  /// Retrieves the secret token for the given [connectionId], or null if not set.
  Future<String?> getToken(String connectionId) async {
    try {
      return await _storage.read(
        key: StorageKeys.tokenKey(connectionId),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {
      return null;
    }
  }

  /// Deletes the secret token for the given [connectionId].
  Future<void> deleteToken(String connectionId) async {
    try {
      await _storage.delete(
        key: StorageKeys.tokenKey(connectionId),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {}
  }

  /// Checks if a token exists for the given [connectionId].
  Future<bool> hasToken(String connectionId) async {
    final token = await getToken(connectionId);
    return token != null && token.isNotEmpty;
  }
}
