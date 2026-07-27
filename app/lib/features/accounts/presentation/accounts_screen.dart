import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/formatters/money_formatter.dart';
import '../../../shared/strings/app_strings.dart';
import '../../../shared/widgets/async_list_scaffold.dart';
import '../providers/accounts_provider.dart';
import 'account_form_sheet.dart';
import 'widgets/account_card.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsControllerProvider);
    final filter = ref.watch(accountsFilterProvider);

    Future<void> confirmDelete(String id, String name) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.deleteAccountTitle),
          content: Text(AppStrings.deleteAccountMessage(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.deleteAction),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      try {
        await ref.read(accountsControllerProvider.notifier).delete(id);
      } on ApiException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
      }
    }

    return AsyncListScaffold(
      title: AppStrings.accountsTitle,
      isLoading: accountsAsync.isLoading,
      error: accountsAsync.hasError ? accountsAsync.error : null,
      isEmpty: accountsAsync.hasValue && accountsAsync.requireValue.isEmpty,
      onRetry: () => ref.read(accountsControllerProvider.notifier).refresh(),
      emptyTitle: AppStrings.accountsEmpty,
      emptyActionLabel: AppStrings.createFirstAccount,
      onEmptyAction: () => showAccountFormSheet(context),
      actions: [
        FilterChip(
          label: const Text(AppStrings.showArchived),
          selected: filter.includeArchived,
          onSelected: (selected) {
            ref.read(accountsFilterProvider.notifier).state =
                filter.copyWith(includeArchived: selected);
          },
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAccountFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (accounts) {
          final total = accounts.fold<Decimal>(
            Decimal.zero,
            (sum, account) => sum + account.currentBalanceDecimal,
          );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length + 1,
            itemBuilder: (context, index) {
              if (index == accounts.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.totalLabel, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        MoneyFormatter.format(total),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: total < Decimal.zero
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                      ),
                    ],
                  ),
                );
              }

              final account = accounts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AccountCard(
                  account: account,
                  onTap: () => showAccountFormSheet(context, account: account),
                  onDelete: () => confirmDelete(account.id, account.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
