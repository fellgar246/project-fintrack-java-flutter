import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/auth_response.dart';
import 'models/tokens_model.dart';

/// Thin wrapper over `/auth/*` (§4.1): JSON in, typed model out. No token
/// handling here — that belongs to `TokenStorage`/`AuthRepository`.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      return AuthResponse.fromJson(response.data!);
    });
  }

  Future<AuthResponse> login({required String email, required String password}) {
    return _guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthResponse.fromJson(response.data!);
    });
  }

  Future<TokensModel> refresh(String refreshToken) {
    return _guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return TokensModel.fromJson(response.data!);
    });
  }

  Future<void> logout(String refreshToken) {
    return _guarded(() => _dio.post<void>(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        ));
  }

  Future<T> _guarded<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(dioProvider)));
