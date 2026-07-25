import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Cliente Dio compartido por toda la app. Los interceptores de auth
/// (adjuntar access token, refresh automático en 401) se agregan en F1.4.
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
