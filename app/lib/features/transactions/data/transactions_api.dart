import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/page_response.dart';
import 'models/transaction_model.dart';
import 'models/transaction_request.dart';

class TransactionListParams {
  const TransactionListParams({
    this.page = 0,
    this.size = 20,
    this.from,
    this.to,
    this.accountId,
    this.categoryId,
    this.type,
    this.search,
  });

  final int page;
  final int size;
  final DateTime? from;
  final DateTime? to;
  final String? accountId;
  final String? categoryId;
  final TransactionType? type;
  final String? search;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': 'date,desc',
    };
    if (from != null) params['from'] = _formatDate(from!);
    if (to != null) params['to'] = _formatDate(to!);
    if (accountId != null) params['accountId'] = accountId;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (type != null) params['type'] = type!.apiValue;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    return params;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class TransactionsApi {
  TransactionsApi(this._dio);

  final Dio _dio;

  Future<PageResponse<TransactionModel>> list(TransactionListParams params) {
    return _guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: params.toQueryParameters(),
      );
      return PageResponse.fromJson(response.data!, TransactionModel.fromJson);
    });
  }

  Future<TransactionModel> getById(String id) {
    return _guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>('/transactions/$id');
      return TransactionModel.fromJson(response.data!);
    });
  }

  Future<TransactionModel> create(TransactionRequest request) {
    return _guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/transactions',
        data: request.toJson(),
      );
      return TransactionModel.fromJson(response.data!);
    });
  }

  Future<TransactionModel> update(String id, TransactionRequest request) {
    return _guarded(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/transactions/$id',
        data: request.toJson(),
      );
      return TransactionModel.fromJson(response.data!);
    });
  }

  Future<void> delete(String id) {
    return _guarded(() => _dio.delete<void>('/transactions/$id'));
  }

  Future<T> _guarded<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final transactionsApiProvider =
    Provider<TransactionsApi>((ref) => TransactionsApi(ref.read(dioProvider)));
