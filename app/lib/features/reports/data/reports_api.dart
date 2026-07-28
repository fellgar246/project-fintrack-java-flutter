import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/by_category_model.dart';
import 'models/summary_model.dart';
import 'models/trend_model.dart';

class ReportsApi {
  ReportsApi(this._dio);

  final Dio _dio;

  Future<SummaryModel> summary({required String yearMonth}) {
    return _guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/summary',
        queryParameters: {'yearMonth': yearMonth},
      );
      return SummaryModel.fromJson(response.data!);
    });
  }

  Future<List<ByCategoryModel>> byCategory({
    required String yearMonth,
    required String kind,
  }) {
    return _guarded(() async {
      final response = await _dio.get<List<dynamic>>(
        '/reports/by-category',
        queryParameters: {
          'yearMonth': yearMonth,
          'kind': kind,
        },
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(ByCategoryModel.fromJson)
          .toList();
    });
  }

  Future<List<TrendModel>> trend({required int months}) {
    return _guarded(() async {
      final response = await _dio.get<List<dynamic>>(
        '/reports/trend',
        queryParameters: {'months': months},
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(TrendModel.fromJson)
          .toList();
    });
  }

  Future<List<int>> exportCsv({
    required DateTime from,
    required DateTime to,
  }) {
    return _guarded(() async {
      final response = await _dio.get<List<int>>(
        '/reports/export',
        queryParameters: {
          'from': _formatDate(from),
          'to': _formatDate(to),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    });
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<T> _guarded<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final reportsApiProvider = Provider<ReportsApi>((ref) => ReportsApi(ref.read(dioProvider)));
