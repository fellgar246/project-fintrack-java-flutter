import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/transaction_model.dart';
import '../data/transactions_api.dart';
import 'transaction_filters_provider.dart';

class TransactionsListState {
  const TransactionsListState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<TransactionModel> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  TransactionsListState copyWith({
    List<TransactionModel>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TransactionsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TransactionsListController extends AsyncNotifier<TransactionsListState> {
  int _requestGeneration = 0;

  @override
  Future<TransactionsListState> build() async {
    ref.watch(transactionFiltersProvider);
    _requestGeneration++;
    return _fetchPage(page: 0, append: false);
  }

  Future<TransactionsListState> _fetchPage({
    required int page,
    required bool append,
  }) async {
    final generation = _requestGeneration;
    final filters = ref.read(transactionFiltersProvider);
    final api = ref.read(transactionsApiProvider);

    final response = await api.list(
      TransactionListParams(
        page: page,
        from: filters.from,
        to: filters.to,
        accountId: filters.accountId,
        categoryId: filters.categoryId,
        type: filters.type,
        search: filters.search.isEmpty ? null : filters.search,
      ),
    );

    if (generation != _requestGeneration) {
      return state.valueOrNull ??
          const TransactionsListState(items: [], page: 0, hasMore: false);
    }

    final previous = append ? (state.valueOrNull?.items ?? <TransactionModel>[]) : <TransactionModel>[];
    return TransactionsListState(
      items: [...previous, ...response.content],
      page: response.page,
      hasMore: response.hasMore,
    );
  }

  Future<void> refresh() async {
    _requestGeneration++;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(page: 0, append: false));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final nextPage = current.page + 1;
    final generation = _requestGeneration;

    try {
      final filters = ref.read(transactionFiltersProvider);
      final response = await ref.read(transactionsApiProvider).list(
            TransactionListParams(
              page: nextPage,
              from: filters.from,
              to: filters.to,
              accountId: filters.accountId,
              categoryId: filters.categoryId,
              type: filters.type,
              search: filters.search.isEmpty ? null : filters.search,
            ),
          );

      if (generation != _requestGeneration) return;

      final latest = state.valueOrNull;
      if (latest == null) return;

      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...response.content],
          page: response.page,
          hasMore: response.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      if (generation != _requestGeneration) return;
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isLoadingMore: false));
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  void removeItem(String id) {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        items: current.items.where((t) => t.id != id).toList(),
      ),
    );
  }
}

final transactionsListProvider =
    AsyncNotifierProvider<TransactionsListController, TransactionsListState>(
  TransactionsListController.new,
);
