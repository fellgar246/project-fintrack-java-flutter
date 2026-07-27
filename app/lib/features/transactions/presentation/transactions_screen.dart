import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/formatters/date_formatter.dart';
import '../../../shared/strings/app_strings.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../data/models/transaction_model.dart';
import '../data/transactions_api.dart';
import '../providers/transaction_filters_provider.dart';
import '../providers/transactions_list_provider.dart';
import 'widgets/day_group_header.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      ref.read(transactionsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final filters = ref.read(transactionFiltersProvider);
      ref.read(transactionFiltersProvider.notifier).state =
          filters.copyWith(search: value.trim());
    });
  }

  Future<bool> _confirmDelete(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteTransactionTitle),
        content: const Text(AppStrings.deleteTransactionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    try {
      await ref.read(transactionsApiProvider).delete(transaction.id);
      ref.read(transactionsListProvider.notifier).removeItem(transaction.id);
      ref.invalidate(accountsControllerProvider);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(transactionsListProvider);
    final filters = ref.watch(transactionFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchTransactions,
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text(AppStrings.transactionsTitle),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchController.clear();
                  _onSearchChanged('');
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsListProvider.notifier).refresh(),
        child: listAsync.when(
          loading: () => _buildSkeletonList(),
          error: (_, _) => _buildError(),
          data: (state) {
            if (state.items.isEmpty) {
              return _buildEmpty(filters);
            }
            return _buildList(state);
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Card(
          child: SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Text(AppStrings.genericError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(transactionsListProvider.notifier).refresh(),
                child: const Text(AppStrings.retryButton),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(TransactionFilters filters) {
    final hasFilters = filters.hasActiveFilters;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const FilterChipsBar(),
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            hasFilters ? AppStrings.transactionsEmptyFiltered : AppStrings.transactionsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: hasFilters
                ? () => ref.read(transactionFiltersProvider.notifier).state =
                    TransactionFilters.currentMonth()
                : () => context.push('/transactions/new'),
            child: Text(hasFilters ? AppStrings.clearAllFilters : AppStrings.registerFirstTransaction),
          ),
        ),
      ],
    );
  }

  Widget _buildList(TransactionsListState state) {
    final groups = _groupByDay(state.items);

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: FilterChipsBar()),
        for (final group in groups) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: DayGroupHeaderDelegate(
              label: DateFormatter.dayHeader(group.date),
              netAmount: dayNetAmount(group.transactions),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final transaction = group.transactions[index];
                return Dismissible(
                  key: ValueKey(transaction.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(transaction),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  child: TransactionTile(
                    transaction: transaction,
                    onTap: () => context.push('/transactions/${transaction.id}'),
                  ),
                );
              },
              childCount: group.transactions.length,
            ),
          ),
        ],
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (!state.hasMore && state.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppStrings.noMoreTransactions,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
      ],
    );
  }

  List<_DayGroup> _groupByDay(List<TransactionModel> items) {
    final map = <DateTime, List<TransactionModel>>{};
    for (final tx in items) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      map.putIfAbsent(day, () => []).add(tx);
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys
        .map((date) => _DayGroup(date: date, transactions: map[date]!))
        .toList();
  }
}

class _DayGroup {
  const _DayGroup({required this.date, required this.transactions});

  final DateTime date;
  final List<TransactionModel> transactions;
}
