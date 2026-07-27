import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/transaction_model.dart';

/// Shared filter state for the transactions list (and future reports screen).
class TransactionFilters {
  const TransactionFilters({
    required this.from,
    required this.to,
    this.type,
    this.accountId,
    this.categoryId,
    this.search = '',
  });

  final DateTime from;
  final DateTime to;
  final TransactionType? type;
  final String? accountId;
  final String? categoryId;
  final String search;

  /// Default range: first day of the current month through today.
  factory TransactionFilters.currentMonth() {
    final now = DateTime.now();
    return TransactionFilters(
      from: DateTime(now.year, now.month),
      to: DateTime(now.year, now.month, now.day),
    );
  }

  TransactionFilters copyWith({
    DateTime? from,
    DateTime? to,
    TransactionType? type,
    String? accountId,
    String? categoryId,
    String? search,
    bool clearType = false,
    bool clearAccountId = false,
    bool clearCategoryId = false,
  }) {
    return TransactionFilters(
      from: from ?? this.from,
      to: to ?? this.to,
      type: clearType ? null : (type ?? this.type),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
    );
  }

  /// Whether the user has applied filters beyond the default month range.
  bool get hasActiveFilters {
    final defaults = TransactionFilters.currentMonth();
    final sameMonthRange = _sameDate(from, defaults.from) && _sameDate(to, defaults.to);
    return !sameMonthRange ||
        type != null ||
        accountId != null ||
        categoryId != null ||
        search.isNotEmpty;
  }

  int get activeFilterCount {
    var count = 0;
    final defaults = TransactionFilters.currentMonth();
    if (!_sameDate(from, defaults.from) || !_sameDate(to, defaults.to)) count++;
    if (type != null) count++;
    if (accountId != null) count++;
    if (categoryId != null) count++;
    if (search.isNotEmpty) count++;
    return count;
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilters &&
          _sameDate(from, other.from) &&
          _sameDate(to, other.to) &&
          type == other.type &&
          accountId == other.accountId &&
          categoryId == other.categoryId &&
          search == other.search;

  @override
  int get hashCode => Object.hash(from, to, type, accountId, categoryId, search);
}

final transactionFiltersProvider =
    StateProvider<TransactionFilters>((ref) => TransactionFilters.currentMonth());
