import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/category_model.dart';

class CategoriesApi {
  CategoriesApi(this._dio);

  final Dio _dio;

  Future<List<CategoryModel>> list({
    CategoryKind? kind,
    bool includeArchived = false,
  }) {
    return _guarded(() async {
      final query = <String, dynamic>{'includeArchived': includeArchived};
      if (kind != null) {
        query['kind'] = kind.apiValue;
      }
      final response = await _dio.get<List<dynamic>>(
        '/categories',
        queryParameters: query,
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    });
  }

  Future<CategoryModel> create({
    required String name,
    required CategoryKind kind,
    required String color,
    required String icon,
  }) {
    return _guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/categories',
        data: {'name': name, 'kind': kind.apiValue, 'color': color, 'icon': icon},
      );
      return CategoryModel.fromJson(response.data!);
    });
  }

  Future<CategoryModel> update({
    required String id,
    required String name,
    required String color,
    required String icon,
  }) {
    return _guarded(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/categories/$id',
        data: {'name': name, 'color': color, 'icon': icon},
      );
      return CategoryModel.fromJson(response.data!);
    });
  }

  Future<void> delete(String id) {
    return _guarded(() => _dio.delete<void>('/categories/$id'));
  }

  Future<T> _guarded<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final categoriesApiProvider =
    Provider<CategoriesApi>((ref) => CategoriesApi(ref.read(dioProvider)));
