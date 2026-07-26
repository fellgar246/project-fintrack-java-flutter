// See the same note in auth_interceptor.dart: named params keep public
// names; an initializing formal would make the private field name external.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../data/models/auth_response.dart';
import '../data/models/user_model.dart';

/// Orchestrates [AuthApi] (HTTP) and [TokenStorage] (persistence) so
/// [AuthController] only ever deals in domain-shaped calls.
class AuthRepository {
  AuthRepository({required AuthApi api, required TokenStorage tokenStorage})
      : _api = api,
        _tokenStorage = tokenStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _api.register(email: email, password: password, name: name);
    await _persistSession(response);
    return response.user;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final response = await _api.login(email: email, password: password);
    await _persistSession(response);
    return response.user;
  }

  /// Revokes the refresh token server-side on a best-effort basis — local
  /// storage is cleared regardless, so logout always works even offline.
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefresh();
    if (refreshToken != null) {
      try {
        await _api.logout(refreshToken);
      } catch (_) {
        // Best-effort: fall through to clearing local storage below.
      }
    }
    await _tokenStorage.clear();
  }

  /// Reads whatever session is cached locally, without a network call —
  /// this is what lets app bootstrap decide `authenticated` vs.
  /// `unauthenticated` instantly, with no login->dashboard flicker.
  Future<UserModel?> restoreSession() async {
    final accessToken = await _tokenStorage.readAccess();
    final userJson = await _tokenStorage.readUserJson();
    if (accessToken == null || userJson == null) {
      return null;
    }
    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSession(AuthResponse response) async {
    await _tokenStorage.saveTokens(
      accessToken: response.tokens.accessToken,
      refreshToken: response.tokens.refreshToken,
    );
    await _tokenStorage.saveUserJson(jsonEncode(response.user.toJson()));
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      api: ref.read(authApiProvider),
      tokenStorage: ref.read(tokenStorageProvider),
    ));
