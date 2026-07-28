import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/by_category_model.dart';
import '../data/models/trend_model.dart';
import '../data/reports_api.dart';

enum ReportKind { expense, income }

String reportKindApiValue(ReportKind kind) =>
    kind == ReportKind.expense ? 'EXPENSE' : 'INCOME';

final selectedReportMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final selectedReportKindProvider =
    StateProvider<ReportKind>((ref) => ReportKind.expense);

final selectedTrendMonthsProvider = StateProvider<int>((ref) => 6);

class ByCategoryController extends FamilyAsyncNotifier<List<ByCategoryModel>, String> {
  @override
  Future<List<ByCategoryModel>> build(String key) async {
    final parts = key.split('|');
    final yearMonth = parts[0];
    final kind = parts[1];
    return ref.read(reportsApiProvider).byCategory(yearMonth: yearMonth, kind: kind);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final parts = arg.split('|');
      return ref.read(reportsApiProvider).byCategory(
            yearMonth: parts[0],
            kind: parts[1],
          );
    });
  }
}

final byCategoryProvider =
    AsyncNotifierProvider.family<ByCategoryController, List<ByCategoryModel>, String>(
  ByCategoryController.new,
);

class TrendController extends FamilyAsyncNotifier<List<TrendModel>, int> {
  @override
  Future<List<TrendModel>> build(int months) async {
    return ref.read(reportsApiProvider).trend(months: months);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reportsApiProvider).trend(months: arg),
    );
  }
}

final trendProvider =
    AsyncNotifierProvider.family<TrendController, List<TrendModel>, int>(
  TrendController.new,
);

String byCategoryKey(String yearMonth, ReportKind kind) =>
    '$yearMonth|${reportKindApiValue(kind)}';
