import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps `flutter_secure_storage` for auth-session persistence: the two JWT
/// tokens plus a cached copy of the user profile (as raw JSON — this layer
/// stays agnostic of the `UserModel` type). The cached user is what lets the
/// app render `authenticated` right at bootstrap without a network round
/// trip: the backend contract has no `/auth/me` endpoint.
///
/// On web, `flutter_secure_storage` falls back to browser storage instead of
/// OS-level encryption. Not a concern yet since web isn't a target platform.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    return Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> readAccess() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefresh() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUserJson(String userJson) =>
      _storage.write(key: _userKey, value: userJson);

  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> clear() {
    return Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
    ]);
  }
}
