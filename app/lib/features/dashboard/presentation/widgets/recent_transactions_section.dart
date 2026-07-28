import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/strings/app_strings.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    required this.transactionsAsync,
    required this.onRetry,
  });

  final AsyncValue<List<TransactionModel>> transactionsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.transactionsTitle, style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => context.go('/transactions'),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        transactionsAsync.when(
          loading: () => const _SectionSkeleton(itemCount: 3),
          error: (_, __) => _SectionError(onRetry: onRetry),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Text(
                AppStrings.transactionsEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: transactions.map((tx) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: TransactionTile(
                    transaction: tx,
                    onTap: () => context.push('/transactions/${tx.id}'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Card(
            child: SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
          ),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

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
