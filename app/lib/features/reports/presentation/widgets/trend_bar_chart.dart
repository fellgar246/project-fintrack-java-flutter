import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/trend_model.dart';

String abbreviateMoney(Decimal amount) {
  final value = amount.toDouble().abs();
  final sign = amount < Decimal.zero ? '-' : '';
  if (value >= 1000000) {
    return '$sign\$${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '$sign\$${(value / 1000).toStringAsFixed(1)}k';
  }
  return '$sign\$${value.toStringAsFixed(0)}';
}

class TrendBarChart extends StatelessWidget {
  const TrendBarChart({
    super.key,
    required this.trend,
  });

  final List<TrendModel> trend;

  static const _monthLabels = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _monthLabel(String yearMonth) {
    final parts = yearMonth.split('-');
    if (parts.length != 2) return yearMonth;
    final month = int.tryParse(parts[1]) ?? 1;
    return _monthLabels[month - 1];
  }

  double _maxY() {
    if (trend.isEmpty) return 100;
    var max = 0.0;
    for (final row in trend) {
      max = [max, row.incomeDecimal.toDouble(), row.expenseDecimal.toDouble()]
          .reduce((a, b) => a > b ? a : b);
    }
    return max <= 0 ? 100 : max * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final maxY = _maxY();
    final labelColor = theme.colorScheme.onSurfaceVariant;

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final row = trend[group.x.toInt()];
                final isIncome = rodIndex == 0;
                final amount = isIncome ? row.incomeDecimal : row.expenseDecimal;
                final label = isIncome ? 'Ingresos' : 'Gastos';
                return BarTooltipItem(
                  '$label\n\$${amount.toStringAsFixed(2)}',
                  TextStyle(color: theme.colorScheme.onInverseSurface),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    abbreviateMoney(Decimal.parse(value.toStringAsFixed(0))),
                    style: TextStyle(fontSize: 10, color: labelColor),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trend.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _monthLabel(trend[index].yearMonth),
                      style: TextStyle(fontSize: 11, color: labelColor),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: trend.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: row.incomeDecimal.toDouble(),
                  color: Colors.green.shade600,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: row.expenseDecimal.toDouble(),
                  color: Colors.red.shade600,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
