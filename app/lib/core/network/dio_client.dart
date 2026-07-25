import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Dio client shared across the app. Auth interceptors
/// (attach access token, auto-refresh on 401) are added in F1.4.
class DioClient {
  DioClient._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
