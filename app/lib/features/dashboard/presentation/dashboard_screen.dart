import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../accounts/providers/accounts_provider.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../../shared/formatters/date_formatter.dart';
import '../../../../shared/strings/app_strings.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/balance_card.dart';
import 'widgets/month_summary_row.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/top_budgets_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final accountsAsync = ref.watch(accountsControllerProvider);
    final authState = ref.watch(authControllerProvider);

    final userName = authState.valueOrNull?.maybeWhen(
          authenticated: (user) => user.name,
          orElse: () => '',
        ) ??
        '';

    final hasNoAccounts = accountsAsync.valueOrNull?.isEmpty ?? false;

    return Scaffold(
      floatingActionButton: hasNoAccounts
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/transactions/new'),
              child: const Icon(Icons.add),
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(accountsControllerProvider);
          await ref.read(dashboardProvider.future);
        },
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(dashboardProvider),
              child: const Text(AppStrings.retryButton),
            ),
          ),
          data: (state) {
            if (hasNoAccounts) {
              return _OnboardingView(
                userName: userName,
                onCreateAccount: () => context.push('/settings/accounts'),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _GreetingHeader(userName: userName),
                const SizedBox(height: 16),
                state.summary.when(
                  loading: () => const Card(
                    child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                  ),
                  error: (_, __) => _InlineError(
                    onRetry: () => _retrySummary(ref),
                  ),
                  data: (summary) => Column(
                    children: [
                      BalanceCard(totalBalance: summary.totalBalance),
                      const SizedBox(height: 12),
                      MonthSummaryRow(
                        income: summary.totalIncomeDecimal,
                        expense: summary.totalExpenseDecimal,
                        net: summary.netDecimal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TopBudgetsSection(
                  budgetsAsync: state.budgets,
                  onRetry: () => _retryBudgets(ref),
                ),
                const SizedBox(height: 24),
                RecentTransactionsSection(
                  transactionsAsync: state.recentTransactions,
                  onRetry: () => _retryTransactions(ref),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _retrySummary(WidgetRef ref) {
    ref.invalidate(dashboardProvider);
  }

  void _retryBudgets(WidgetRef ref) {
    ref.invalidate(dashboardProvider);
  }

  void _retryTransactions(WidgetRef ref) {
    ref.invalidate(dashboardProvider);
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName.isNotEmpty ? 'Hola, $userName' : 'Hola',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          DateFormatter.monthYear(now),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({
    required this.userName,
    required this.onCreateAccount,
  });

  final String userName;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              userName.isNotEmpty ? 'Hola, $userName' : 'Hola',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.createFirstAccount,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateAccount,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.createFirstAccount),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});

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
