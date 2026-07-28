import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budgets/data/budgets_api.dart';
import '../../budgets/data/models/budget_model.dart';
import '../../budgets/providers/budgets_provider.dart';
import '../../transactions/data/models/transaction_model.dart';
import '../../transactions/data/transactions_api.dart';
import '../../reports/data/models/summary_model.dart';
import '../../reports/data/reports_api.dart';

class DashboardState {
  const DashboardState({
    required this.summary,
    required this.budgets,
    required this.recentTransactions,
  });

  final AsyncValue<SummaryModel> summary;
  final AsyncValue<List<BudgetModel>> budgets;
  final AsyncValue<List<TransactionModel>> recentTransactions;

  DashboardState copyWith({
    AsyncValue<SummaryModel>? summary,
    AsyncValue<List<BudgetModel>>? budgets,
    AsyncValue<List<TransactionModel>>? recentTransactions,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      budgets: budgets ?? this.budgets,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}

class DashboardController extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    return _loadAll();
  }

  Future<DashboardState> _loadAll() async {
    final yearMonth = yearMonthKey(DateTime.now());

    final results = await Future.wait([
      _guard(() => ref.read(reportsApiProvider).summary(yearMonth: yearMonth)),
      _guard(() => ref.read(budgetsApiProvider).list(yearMonth: yearMonth)),
      _guard(() => ref.read(transactionsApiProvider).list(
            const TransactionListParams(page: 0, size: 5),
          ).then((page) => page.content)),
    ]);

    return DashboardState(
      summary: results[0] as AsyncValue<SummaryModel>,
      budgets: results[1] as AsyncValue<List<BudgetModel>>,
      recentTransactions: results[2] as AsyncValue<List<TransactionModel>>,
    );
  }

  Future<AsyncValue<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return AsyncValue.data(await call());
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadAll);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardController, DashboardState>(DashboardController.new);

void invalidateDashboard(Ref ref) {
  ref.invalidate(dashboardProvider);
}
