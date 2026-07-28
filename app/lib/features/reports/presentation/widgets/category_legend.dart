import 'package:flutter/material.dart';

import '../../../../shared/formatters/money_formatter.dart';
import 'category_donut_chart.dart';

class CategoryLegend extends StatelessWidget {
  const CategoryLegend({
    super.key,
    required this.slices,
  });

  final List<CategoryChartSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return const SizedBox.shrink();

    return Column(
      children: slices.map((slice) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: slice.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(slice.label)),
              Text(
                MoneyFormatter.format(slice.total),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  '${slice.percent.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
