import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budgets/presentation/widgets/month_selector.dart';
import '../../budgets/providers/budgets_provider.dart';
import '../providers/reports_provider.dart';
import '../../../../shared/strings/app_strings.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/category_legend.dart';
import 'widgets/export_button.dart';
import 'widgets/trend_bar_chart.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  DateTime _maxMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime _minMonth() => DateTime(2020);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedReportMonthProvider);
    final kind = ref.watch(selectedReportKindProvider);
    final trendMonths = ref.watch(selectedTrendMonthsProvider);
    final yearMonth = yearMonthKey(selectedMonth);
    final categoryKey = byCategoryKey(yearMonth, kind);

    final byCategoryAsync = ref.watch(byCategoryProvider(categoryKey));
    final trendAsync = ref.watch(trendProvider(trendMonths));

    Future<void> pickMonth() async {
      final picked = await showMonthYearPicker(
        context: context,
        initialMonth: selectedMonth,
        minMonth: _minMonth(),
        maxMonth: _maxMonth(),
      );
      if (picked != null) {
        ref.read(selectedReportMonthProvider.notifier).state =
            DateTime(picked.year, picked.month);
      }
    }

    void goToMonth(DateTime month) {
      ref.read(selectedReportMonthProvider.notifier).state =
          DateTime(month.year, month.month);
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reportsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(byCategoryProvider(categoryKey));
          ref.invalidate(trendProvider(trendMonths));
          await Future.wait([
            ref.read(byCategoryProvider(categoryKey).future),
            ref.read(trendProvider(trendMonths).future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MonthSelector(
              selectedMonth: selectedMonth,
              onPrevious: () => goToMonth(previousMonth(selectedMonth)),
              onNext: () => goToMonth(
                DateTime(selectedMonth.year, selectedMonth.month + 1),
              ),
              onPickMonth: pickMonth,
              canGoPrevious: selectedMonth.isAfter(_minMonth()),
              canGoNext: selectedMonth.year < _maxMonth().year ||
                  (selectedMonth.year == _maxMonth().year &&
                      selectedMonth.month < _maxMonth().month),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ReportKind>(
              segments: [
                const ButtonSegment(
                  value: ReportKind.expense,
                  label: Text(AppStrings.expenseTab),
                ),
                const ButtonSegment(
                  value: ReportKind.income,
                  label: Text(AppStrings.incomeTab),
                ),
              ],
              selected: {kind},
              onSelectionChanged: (selection) {
                ref.read(selectedReportKindProvider.notifier).state = selection.first;
              },
            ),
            const SizedBox(height: 16),
            Text(AppStrings.reportsByCategory, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            byCategoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(byCategoryProvider(categoryKey)),
                  child: const Text(AppStrings.retryButton),
                ),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const _EmptyChartMessage(message: AppStrings.reportsNoData);
                }

                final slices = buildCategorySlices(categories);
                final total = categories.fold<Decimal>(
                  Decimal.zero,
                  (sum, c) => sum + Decimal.parse(c.total),
                );

                return Column(
                  children: [
                    CategoryDonutChart(slices: slices, centerTotal: total),
                    const SizedBox(height: 16),
                    CategoryLegend(slices: slices),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.reportsTrend, style: Theme.of(context).textTheme.titleMedium),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 3, label: Text('3M')),
                    ButtonSegment(value: 6, label: Text('6M')),
                    ButtonSegment(value: 12, label: Text('12M')),
                  ],
                  selected: {trendMonths},
                  onSelectionChanged: (selection) {
                    ref.read(selectedTrendMonthsProvider.notifier).state = selection.first;
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            trendAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(trendProvider(trendMonths)),
                  child: const Text(AppStrings.retryButton),
                ),
              ),
              data: (trend) {
                final hasData = trend.any(
                  (row) =>
                      row.incomeDecimal > Decimal.zero || row.expenseDecimal > Decimal.zero,
                );
                if (!hasData) {
                  return const _EmptyChartMessage(message: AppStrings.reportsNoData);
                }
                return TrendBarChart(trend: trend);
              },
            ),
            const SizedBox(height: 32),
            const Center(child: ExportButton()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EmptyChartMessage extends StatelessWidget {
  const _EmptyChartMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
