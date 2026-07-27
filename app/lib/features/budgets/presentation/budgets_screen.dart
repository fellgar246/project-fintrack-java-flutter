import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/strings/app_strings.dart';
import '../../../shared/widgets/async_list_scaffold.dart';
import '../data/models/budget_model.dart';
import '../providers/budgets_provider.dart';
import 'budget_form_sheet.dart';
import 'widgets/budget_card.dart';
import 'widgets/month_selector.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  DateTime _maxMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 12);
  }

  DateTime _minMonth() {
    return DateTime(2020);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final yearMonth = yearMonthKey(selectedMonth);
    final budgetsAsync = ref.watch(budgetsProvider(yearMonth));
    final maxMonth = _maxMonth();
    final minMonth = _minMonth();

    Future<void> pickMonth() async {
      final picked = await showMonthYearPicker(
        context: context,
        initialMonth: selectedMonth,
        minMonth: minMonth,
        maxMonth: maxMonth,
      );
      if (picked != null) {
        ref.read(selectedBudgetMonthProvider.notifier).state =
            DateTime(picked.year, picked.month);
      }
    }

    void goToMonth(DateTime month) {
      ref.read(selectedBudgetMonthProvider.notifier).state =
          DateTime(month.year, month.month);
    }

    Future<void> confirmDelete(BudgetModel budget) async {
      if (budget.id == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.deleteBudgetTitle),
          content: Text(AppStrings.deleteBudgetMessage(budget.category.name)),
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

      if (confirmed != true || !context.mounted) return;

      try {
        await ref.read(budgetsProvider(yearMonth).notifier).delete(budget.id!);
      } on ApiException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
      }
    }

    Future<void> copyFromPrevious() async {
      try {
        await ref.read(budgetsProvider(yearMonth).notifier).copyFromPreviousMonth();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.budgetsCopied)),
          );
        }
      } on ApiException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
      }
    }

    final budgeted = budgetsAsync.valueOrNull?.where((b) => b.hasBudget).toList() ?? [];
    final unbudgeted = budgetsAsync.valueOrNull?.where((b) => !b.hasBudget).toList() ?? [];
    final isEmpty = budgeted.isEmpty && unbudgeted.isEmpty;

    return AsyncListScaffold(
      title: AppStrings.budgetsTitle,
      isLoading: budgetsAsync.isLoading,
      error: budgetsAsync.hasError ? budgetsAsync.error : null,
      isEmpty: budgetsAsync.hasValue && isEmpty,
      onRetry: () => ref.read(budgetsProvider(yearMonth).notifier).refresh(),
      emptyTitle: AppStrings.budgetsEmpty,
      emptyActionLabel: AppStrings.createFirstBudget,
      onEmptyAction: () => showBudgetFormSheet(context, yearMonth: yearMonth),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBudgetFormSheet(context, yearMonth: yearMonth),
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (budgets) {
          final budgetedItems = budgets.where((b) => b.hasBudget).toList();
          final unbudgetedItems = budgets.where((b) => !b.hasBudget).toList();

          final totalLimit = budgetedItems.fold<Decimal>(
            Decimal.zero,
            (sum, b) => sum + b.limitAmountDecimal!,
          );
          final totalSpent = budgetedItems.fold<Decimal>(
            Decimal.zero,
            (sum, b) => sum + b.spentAmountDecimal,
          );
          final globalPercent = totalLimit > Decimal.zero
              ? totalSpent.toDouble() / totalLimit.toDouble() * 100
              : 0.0;
          final globalStatus = _resolveStatus(globalPercent);

          final showCopyAction = budgetedItems.isEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MonthSelector(
                selectedMonth: selectedMonth,
                onPrevious: () => goToMonth(previousMonth(selectedMonth)),
                onNext: () {
                  final next = DateTime(selectedMonth.year, selectedMonth.month + 1);
                  goToMonth(next);
                },
                onPickMonth: pickMonth,
                canGoPrevious: selectedMonth.isAfter(minMonth),
                canGoNext: selectedMonth.year < maxMonth.year ||
                    (selectedMonth.year == maxMonth.year &&
                        selectedMonth.month < maxMonth.month),
              ),
              if (showCopyAction) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: copyFromPrevious,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text(AppStrings.copyFromPreviousMonth),
                  ),
                ),
              ],
              if (budgetedItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                BudgetSummaryCard(
                  totalLimit: totalLimit,
                  totalSpent: totalSpent,
                  percentUsed: globalPercent,
                  status: globalStatus,
                ),
              ],
              if (budgetedItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.budgetByCategory,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...budgetedItems.map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BudgetCard(
                      budget: budget,
                      onTap: () => showBudgetFormSheet(
                        context,
                        yearMonth: yearMonth,
                        budget: budget,
                      ),
                      onDelete: () => confirmDelete(budget),
                    ),
                  ),
                ),
              ],
              if (unbudgetedItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  AppStrings.unbudgetedSection,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...unbudgetedItems.map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BudgetCard(
                      budget: budget,
                      compact: true,
                      onTap: () => showBudgetFormSheet(
                        context,
                        yearMonth: yearMonth,
                        preselectedCategoryId: budget.category.id,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  BudgetStatus _resolveStatus(double percentUsed) {
    if (percentUsed >= 100) return BudgetStatus.exceeded;
    if (percentUsed >= 70) return BudgetStatus.warning;
    return BudgetStatus.ok;
  }
}
