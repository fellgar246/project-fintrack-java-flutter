import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/formatters/money_formatter.dart';
import '../../data/models/by_category_model.dart';

class CategoryChartSlice {
  const CategoryChartSlice({
    required this.label,
    required this.color,
    required this.total,
    required this.percent,
    this.isOthers = false,
  });

  final String label;
  final Color color;
  final Decimal total;
  final double percent;
  final bool isOthers;
}

List<CategoryChartSlice> buildCategorySlices(List<ByCategoryModel> categories) {
  if (categories.isEmpty) return [];

  if (categories.length <= 8) {
    return categories.map((c) {
      return CategoryChartSlice(
        label: c.name,
        color: _parseColor(c.color),
        total: Decimal.parse(c.total),
        percent: c.percent,
      );
    }).toList();
  }

  final top = categories.take(7).toList();
  final others = categories.skip(7).toList();
  final othersTotal = others.fold<Decimal>(
    Decimal.zero,
    (sum, c) => sum + Decimal.parse(c.total),
  );
  final othersPercent = others.fold<double>(0, (sum, c) => sum + c.percent);

  final slices = top.map((c) {
    return CategoryChartSlice(
      label: c.name,
      color: _parseColor(c.color),
      total: Decimal.parse(c.total),
      percent: c.percent,
    );
  }).toList();

  slices.add(CategoryChartSlice(
    label: 'Otros',
    color: Colors.grey.shade600,
    total: othersTotal,
    percent: othersPercent,
    isOthers: true,
  ));

  return slices;
}

Color _parseColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
}

class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({
    super.key,
    required this.slices,
    required this.centerTotal,
  });

  final List<CategoryChartSlice> slices;
  final Decimal centerTotal;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.slices.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final touched = _touchedIndex;

    return AspectRatio(
      aspectRatio: 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 64,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      _touchedIndex = null;
                      return;
                    }
                    _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: widget.slices.asMap().entries.map((entry) {
                final index = entry.key;
                final slice = entry.value;
                final isTouched = touched == index;
                final radius = isTouched ? 52.0 : 44.0;

                return PieChartSectionData(
                  value: slice.percent,
                  color: slice.color,
                  radius: radius,
                  title: '',
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
          if (touched != null && touched < widget.slices.length)
            _CenterDetail(slice: widget.slices[touched])
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  MoneyFormatter.format(widget.centerTotal),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CenterDetail extends StatelessWidget {
  const _CenterDetail({required this.slice});

  final CategoryChartSlice slice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slice.label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            MoneyFormatter.format(slice.total),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            '${slice.percent.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
