import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/budgets_api.dart';
import '../data/models/budget_model.dart';

/// Selected month for the budgets screen (always normalized to day 1).
final selectedBudgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

String yearMonthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

DateTime previousMonth(DateTime date) {
  if (date.month == 1) {
    return DateTime(date.year - 1, 12);
  }
  return DateTime(date.year, date.month - 1);
}

class BudgetsController extends FamilyAsyncNotifier<List<BudgetModel>, String> {
  @override
  Future<List<BudgetModel>> build(String yearMonth) async {
    return ref.read(budgetsApiProvider).list(
          yearMonth: yearMonth,
          includeUnbudgeted: true,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(budgetsApiProvider).list(
            yearMonth: arg,
            includeUnbudgeted: true,
          ),
    );
  }

  Future<void> upsert({
    required String categoryId,
    required String limitAmount,
  }) async {
    await ref.read(budgetsApiProvider).upsert(
          categoryId: categoryId,
          yearMonth: arg,
          limitAmount: limitAmount,
        );
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(budgetsApiProvider).delete(id);
    ref.invalidateSelf();
  }

  Future<void> copyFromPreviousMonth() async {
    final previousKey = yearMonthKey(previousMonth(_parseYearMonth(arg)));
    final previousBudgets = await ref.read(budgetsApiProvider).list(
          yearMonth: previousKey,
          includeUnbudgeted: false,
        );

    for (final budget in previousBudgets) {
      if (budget.limitAmount == null) continue;
      await ref.read(budgetsApiProvider).upsert(
            categoryId: budget.category.id,
            yearMonth: arg,
            limitAmount: budget.limitAmount!,
          );
    }

    ref.invalidateSelf();
  }

  DateTime _parseYearMonth(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }
}

final budgetsProvider = AsyncNotifierProvider.family<BudgetsController, List<BudgetModel>, String>(
  BudgetsController.new,
);

/// Invalidates the budgets list for the month currently visible in the UI.
void invalidateVisibleBudgets(Ref ref) {
  final month = ref.read(selectedBudgetMonthProvider);
  ref.invalidate(budgetsProvider(yearMonthKey(month)));
}
