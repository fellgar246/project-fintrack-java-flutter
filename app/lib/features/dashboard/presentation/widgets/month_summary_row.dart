import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/formatters/money_formatter.dart';
import '../../../../shared/strings/app_strings.dart';

class MonthSummaryRow extends StatelessWidget {
  const MonthSummaryRow({
    super.key,
    required this.income,
    required this.expense,
    required this.net,
  });

  final Decimal income;
  final Decimal expense;
  final Decimal net;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _SummaryColumn(
                label: AppStrings.incomeType,
                amount: income,
                color: Colors.green.shade700,
                icon: Icons.arrow_upward,
              ),
            ),
            Expanded(
              child: _SummaryColumn(
                label: AppStrings.expenseType,
                amount: expense,
                color: Colors.red.shade700,
                icon: Icons.arrow_downward,
              ),
            ),
            Expanded(
              child: _SummaryColumn(
                label: 'Neto',
                amount: net,
                color: net >= Decimal.zero
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                icon: net >= Decimal.zero ? Icons.trending_up : Icons.trending_down,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final Decimal amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          MoneyFormatter.format(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
