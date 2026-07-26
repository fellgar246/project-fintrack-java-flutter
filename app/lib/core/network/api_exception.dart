import 'package:dio/dio.dart';

/// Typed error parsed from the backend's RFC 7807 Problem Details body (§4.7
/// of the master plan): `{type, title, status, detail, instance, errors}`.
///
/// `fieldErrors` maps `field -> message` so forms can paint the error
/// directly under the matching `TextFormField` instead of a generic banner.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.title,
    required this.detail,
    this.fieldErrors = const {},
  });

  /// Backend unreachable, timed out, or replied with a body that isn't
  /// Problem Details (e.g. the server is down and a proxy returns HTML).
  factory ApiException.connection() => const ApiException(
        status: 0,
        title: 'Sin conexión',
        detail: 'No se pudo conectar con el servidor',
      );

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final body = response?.data;
    if (response == null || body is! Map) {
      return ApiException.connection();
    }

    final status = (body['status'] as num?)?.toInt() ?? response.statusCode ?? 0;
    final title = body['title'] as String? ?? 'Error';
    final detail =
        body['detail'] as String? ?? 'No se pudo conectar con el servidor';

    final fieldErrors = <String, String>{};
    final rawErrors = body['errors'];
    if (rawErrors is List) {
      for (final item in rawErrors) {
        if (item is Map) {
          final field = item['field'] as String?;
          final message = item['message'] as String?;
          if (field != null && message != null) {
            fieldErrors[field] = message;
          }
        }
      }
    }

    return ApiException(
      status: status,
      title: title,
      detail: detail,
      fieldErrors: fieldErrors,
    );
  }

  final int status;
  final String title;
  final String detail;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => status == 401;
  bool get isConflict => status == 409;

  @override
  String toString() => 'ApiException(status: $status, title: $title, detail: $detail)';
}
