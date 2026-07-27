import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/budget_model.dart';

class BudgetsApi {
  BudgetsApi(this._dio);

  final Dio _dio;

  Future<List<BudgetModel>> list({
    required String yearMonth,
    bool includeUnbudgeted = false,
  }) {
    return _guarded(() async {
      final response = await _dio.get<List<dynamic>>(
        '/budgets',
        queryParameters: {
          'yearMonth': yearMonth,
          'includeUnbudgeted': includeUnbudgeted,
        },
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(BudgetModel.fromJson)
          .toList();
    });
  }

  Future<BudgetModel> upsert({
    required String categoryId,
    required String yearMonth,
    required String limitAmount,
  }) {
    return _guarded(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/budgets',
        data: {
          'categoryId': categoryId,
          'yearMonth': yearMonth,
          'limitAmount': limitAmount,
        },
      );
      return BudgetModel.fromJson(response.data!);
    });
  }

  Future<void> delete(String id) {
    return _guarded(() => _dio.delete<void>('/budgets/$id'));
  }

  Future<T> _guarded<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final budgetsApiProvider = Provider<BudgetsApi>((ref) => BudgetsApi(ref.read(dioProvider)));
