import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/formatters/date_formatter.dart';
import '../../../../shared/strings/app_strings.dart';
import '../../../accounts/data/models/account_model.dart';
import '../../../accounts/providers/accounts_provider.dart';
import '../../../categories/data/categories_api.dart';
import '../../../categories/data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/transaction_filters_provider.dart';

final filterCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) {
  return ref.read(categoriesApiProvider).list(includeArchived: false);
});

class FilterChipsBar extends ConsumerWidget {
  const FilterChipsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transactionFiltersProvider);
    final accountsAsync = ref.watch(accountsControllerProvider);
    final categoriesAsync = ref.watch(filterCategoriesProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: DateFormatter.shortRange(filters.from, filters.to),
            selected: !_isDefaultMonthRange(filters),
            onTap: () => _pickDateRange(context, ref, filters),
            onClear: !_isDefaultMonthRange(filters)
                ? () => ref.read(transactionFiltersProvider.notifier).state =
                    filters.copyWith(
                      from: TransactionFilters.currentMonth().from,
                      to: TransactionFilters.currentMonth().to,
                    )
                : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filters.type != null
                ? _typeLabel(filters.type!)
                : AppStrings.filterType,
            selected: filters.type != null,
            onTap: () => _pickType(context, ref, filters),
            onClear: filters.type != null
                ? () => ref.read(transactionFiltersProvider.notifier).state =
                    filters.copyWith(clearType: true)
                : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filters.accountId != null
                ? _accountName(accountsAsync.valueOrNull, filters.accountId!)
                : AppStrings.filterAccount,
            selected: filters.accountId != null,
            onTap: () => _pickAccount(context, ref, filters, accountsAsync.valueOrNull ?? []),
            onClear: filters.accountId != null
                ? () => ref.read(transactionFiltersProvider.notifier).state =
                    filters.copyWith(clearAccountId: true)
                : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filters.categoryId != null
                ? _categoryName(categoriesAsync.valueOrNull, filters.categoryId!)
                : AppStrings.filterCategory,
            selected: filters.categoryId != null,
            onTap: () => _pickCategory(context, ref, filters, categoriesAsync.valueOrNull ?? []),
            onClear: filters.categoryId != null
                ? () => ref.read(transactionFiltersProvider.notifier).state =
                    filters.copyWith(clearCategoryId: true)
                : null,
          ),
          if (filters.activeFilterCount >= 1) ...[
            const SizedBox(width: 8),
            ActionChip(
              label: const Text(AppStrings.clearAllFilters),
              onPressed: () => ref.read(transactionFiltersProvider.notifier).state =
                  TransactionFilters.currentMonth(),
            ),
          ],
        ],
      ),
    );
  }

  bool _isDefaultMonthRange(TransactionFilters filters) {
    final defaults = TransactionFilters.currentMonth();
    return filters.from.year == defaults.from.year &&
        filters.from.month == defaults.from.month &&
        filters.from.day == defaults.from.day &&
        filters.to.year == defaults.to.year &&
        filters.to.month == defaults.to.month &&
        filters.to.day == defaults.to.day;
  }

  String _typeLabel(TransactionType type) => switch (type) {
        TransactionType.expense => AppStrings.expenseType,
        TransactionType.income => AppStrings.incomeType,
        TransactionType.transfer => AppStrings.transferType,
      };

  String _accountName(List<AccountModel>? accounts, String id) {
    if (accounts == null || accounts.isEmpty) return id;
    return accounts.where((a) => a.id == id).map((a) => a.name).firstOrNull ?? id;
  }

  String _categoryName(List<CategoryModel>? categories, String id) {
    if (categories == null || categories.isEmpty) return id;
    return categories.where((c) => c.id == id).map((c) => c.name).firstOrNull ?? id;
  }

  Future<void> _pickDateRange(
    BuildContext context,
    WidgetRef ref,
    TransactionFilters filters,
  ) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: filters.from, end: filters.to),
    );
    if (range == null) return;
    ref.read(transactionFiltersProvider.notifier).state = filters.copyWith(
      from: DateTime(range.start.year, range.start.month, range.start.day),
      to: DateTime(range.end.year, range.end.month, range.end.day),
    );
  }

  Future<void> _pickType(
    BuildContext context,
    WidgetRef ref,
    TransactionFilters filters,
  ) async {
    final type = await showModalBottomSheet<TransactionType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: TransactionType.values
              .map(
                (t) => ListTile(
                  title: Text(_typeLabel(t)),
                  onTap: () => Navigator.pop(context, t),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (type == null) return;
    ref.read(transactionFiltersProvider.notifier).state = filters.copyWith(type: type);
  }

  Future<void> _pickAccount(
    BuildContext context,
    WidgetRef ref,
    TransactionFilters filters,
    List<AccountModel> accounts,
  ) async {
    final id = await _pickFromList(
      context,
      title: AppStrings.filterAccount,
      items: accounts.map((a) => (a.id, a.name)).toList(),
    );
    if (id == null) return;
    ref.read(transactionFiltersProvider.notifier).state = filters.copyWith(accountId: id);
  }

  Future<void> _pickCategory(
    BuildContext context,
    WidgetRef ref,
    TransactionFilters filters,
    List<CategoryModel> categories,
  ) async {
    final id = await _pickFromList(
      context,
      title: AppStrings.filterCategory,
      items: categories.map((c) => (c.id, c.name)).toList(),
    );
    if (id == null) return;
    ref.read(transactionFiltersProvider.notifier).state = filters.copyWith(categoryId: id);
  }

  Future<String?> _pickFromList(
    BuildContext context, {
    required String title,
    required List<(String, String)> items,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final (id, name) = items[index];
                  return ListTile(
                    title: Text(name),
                    onTap: () => Navigator.pop(context, id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      selected: selected,
      onPressed: onTap,
      deleteIcon: selected && onClear != null ? const Icon(Icons.close, size: 16) : null,
      onDeleted: selected ? onClear : null,
    );
  }
}
