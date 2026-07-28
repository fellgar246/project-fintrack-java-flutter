import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/strings/app_strings.dart';
import '../../../budgets/data/models/budget_model.dart';
import '../../../budgets/presentation/widgets/budget_progress_bar.dart';
import '../../../../shared/formatters/money_formatter.dart';
import '../../../../shared/icons/material_icon_helper.dart';

class TopBudgetsSection extends StatelessWidget {
  const TopBudgetsSection({
    super.key,
    required this.budgetsAsync,
    required this.onRetry,
  });

  final AsyncValue<List<BudgetModel>> budgetsAsync;
  final VoidCallback onRetry;

  List<BudgetModel> _topBudgets(List<BudgetModel> budgets) {
    final withBudget = budgets.where((b) => b.hasBudget && b.percentUsed != null).toList()
      ..sort((a, b) => (b.percentUsed ?? 0).compareTo(a.percentUsed ?? 0));
    return withBudget.take(3).toList();
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Presupuestos',
          actionLabel: 'Ver todos',
          onAction: () => context.go('/budgets'),
        ),
        const SizedBox(height: 8),
        budgetsAsync.when(
          loading: () => const _SectionSkeleton(itemCount: 2),
          error: (_, __) => _SectionError(onRetry: onRetry),
          data: (budgets) {
            final top = _topBudgets(budgets);
            if (top.isEmpty) {
              return Text(
                AppStrings.budgetsEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: top.map((budget) {
                final percent = budget.percentUsed ?? 0;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _parseColor(budget.category.color),
                      child: Icon(
                        MaterialIconHelper.resolve(budget.category.icon),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(budget.category.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${MoneyFormatter.format(budget.spentAmountDecimal)} / ${MoneyFormatter.format(budget.limitAmountDecimal!)}',
                        ),
                        const SizedBox(height: 6),
                        BudgetProgressBar(
                          percentUsed: percent,
                          status: budget.status!,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Card(
            child: SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
          ),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(child: Text(AppStrings.genericError)),
            TextButton(onPressed: onRetry, child: const Text(AppStrings.retryButton)),
          ],
        ),
      ),
    );
  }
}
