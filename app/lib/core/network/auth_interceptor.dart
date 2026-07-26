// Named constructor params keep public names (dio, tokenStorage, ...) for a
// readable call site; an initializing formal would force the private field
// name as the external name, which other files couldn't call by name.
// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Injects `Authorization: Bearer <token>` into every request and
/// transparently refreshes the session on a 401.
///
/// The delicate part is concurrency. The backend **rotates** the refresh
/// token on every call to `/auth/refresh` (the old one is revoked
/// server-side the moment a new pair is issued). If N parallel requests each
/// hit a 401 and each raced to call `/auth/refresh` on their own, only the
/// first would succeed — the rest would submit an already-revoked refresh
/// token and log the user out. So instead, the first 401 kicks off a single
/// refresh `Future` that every other 401 arriving while it's in flight just
/// awaits; nobody but that first request ever calls `/auth/refresh`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required void Function() onSessionExpired,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function() _onSessionExpired;

  Future<String?>? _refreshFuture;

  static const _noAuthHeaderPaths = ['/auth/login', '/auth/register', '/auth/refresh'];
  static const _retriedFlag = 'auth_interceptor_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_matchesAny(options.path, _noAuthHeaderPaths)) {
      final accessToken = await _tokenStorage.readAccess();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isAuthRequest = options.path.contains('/auth/');
    final alreadyRetried = options.extra[_retriedFlag] == true;

    if (err.response?.statusCode != 401 || isAuthRequest || alreadyRetried) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refresh();
    if (newAccessToken == null) {
      _onSessionExpired();
      handler.next(err);
      return;
    }

    try {
      options.extra[_retriedFlag] = true;
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(options);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Returns the shared in-flight refresh, starting one if none is running.
  Future<String?> _refresh() {
    return _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefresh();
    if (refreshToken == null) {
      await _tokenStorage.clear();
      return null;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final tokens = response.data!;
      final accessToken = tokens['accessToken'] as String;
      final newRefreshToken = tokens['refreshToken'] as String;
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return accessToken;
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }

  bool _matchesAny(String path, List<String> candidates) =>
      candidates.any(path.contains);
}
