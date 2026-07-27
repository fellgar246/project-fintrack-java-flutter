import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/formatters/money_formatter.dart';

class DayGroupHeader extends StatelessWidget {
  const DayGroupHeader({
    super.key,
    required this.label,
    required this.netAmount,
  });

  final String label;
  final Decimal netAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netColor = netAmount > Decimal.zero
        ? Colors.green.shade700
        : netAmount < Decimal.zero
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            MoneyFormatter.format(netAmount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: netColor,
            ),
          ),
        ],
      ),
    );
  }
}

class DayGroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  DayGroupHeaderDelegate({
    required this.label,
    required this.netAmount,
  });

  final String label;
  final Decimal netAmount;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DayGroupHeader(label: label, netAmount: netAmount);
  }

  @override
  bool shouldRebuild(covariant DayGroupHeaderDelegate oldDelegate) =>
      label != oldDelegate.label || netAmount != oldDelegate.netAmount;
}
