import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/account_model.dart';

class AccountsApi {
  AccountsApi(this._dio);

  final Dio _dio;

  Future<List<AccountModel>> list({bool includeArchived = false}) {
    return _guarded(() async {
      final response = await _dio.get<List<dynamic>>(
        '/accounts',
        queryParameters: {'includeArchived': includeArchived},
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(AccountModel.fromJson)
          .toList();
    });
  }

  Future<AccountModel> create({
    required String name,
    required AccountType type,
    required String initialBalance,
  }) {
    return _guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/accounts',
        data: {'name': name, 'type': type.apiValue, 'initialBalance': initialBalance},
      );
      return AccountModel.fromJson(response.data!);
    });
  }

  Future<AccountModel> update({
    required String id,
    required String name,
    required AccountType type,
    required String initialBalance,
  }) {
    return _guarded(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/accounts/$id',
        data: {'name': name, 'type': type.apiValue, 'initialBalance': initialBalance},
      );
      return AccountModel.fromJson(response.data!);
    });
  }

  Future<void> delete(String id) {
    return _guarded(() => _dio.delete<void>('/accounts/$id'));
  }

  Future<T> _guarded<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final accountsApiProvider = Provider<AccountsApi>((ref) => AccountsApi(ref.read(dioProvider)));
