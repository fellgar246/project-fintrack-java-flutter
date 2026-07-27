import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/formatters/money_formatter.dart';
import '../../../../shared/icons/material_icon_helper.dart';
import '../../../../shared/strings/app_strings.dart';
import '../../data/models/budget_model.dart';
import 'budget_progress_bar.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.onTap,
    this.onDelete,
    this.compact = false,
  });

  final BudgetModel budget;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool compact;

  Color get _categoryColor {
    final hex = budget.category.color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (!budget.hasBudget) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _categoryColor,
            child: Icon(
              MaterialIconHelper.resolve(budget.category.icon),
              color: Colors.white,
            ),
          ),
          title: Text(budget.category.name),
          trailing: TextButton(
            onPressed: onTap,
            child: const Text(AppStrings.defineBudget),
          ),
        ),
      );
    }

    final spent = budget.spentAmountDecimal;
    final limit = budget.limitAmountDecimal!;
    final percent = budget.percentUsed ?? 0;
    final remaining = budget.remainingAmountDecimal ?? Decimal.zero;
    final status = budget.status!;

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _categoryColor,
                    child: Icon(
                      MaterialIconHelper.resolve(budget.category.icon),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      budget.category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      onSelected: (_) => onDelete!(),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(AppStrings.deleteAction),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  '${MoneyFormatter.format(spent)} / ${MoneyFormatter.format(limit)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                BudgetProgressBar(percentUsed: percent, status: status),
                const SizedBox(height: 8),
                Text(
                  remaining >= Decimal.zero
                      ? AppStrings.budgetRemaining(MoneyFormatter.format(remaining))
                      : AppStrings.budgetOver(MoneyFormatter.format(-remaining)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: remaining >= Decimal.zero
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    super.key,
    required this.totalLimit,
    required this.totalSpent,
    required this.percentUsed,
    required this.status,
  });

  final Decimal totalLimit;
  final Decimal totalSpent;
  final double percentUsed;
  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final available = totalLimit - totalSpent;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.budgetSummaryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: AppStrings.budgetTotalLimit,
              value: MoneyFormatter.format(totalLimit),
            ),
            _SummaryRow(
              label: AppStrings.budgetTotalSpent,
              value: MoneyFormatter.format(totalSpent),
            ),
            _SummaryRow(
              label: AppStrings.budgetAvailable,
              value: MoneyFormatter.format(available),
              valueColor: available < Decimal.zero
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            const SizedBox(height: 12),
            BudgetProgressBar(percentUsed: percentUsed, status: status),
            const SizedBox(height: 4),
            Text(
              '${percentUsed.toStringAsFixed(0)}% ${AppStrings.budgetUsedLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
