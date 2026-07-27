import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/formatters/money_formatter.dart';
import '../../../../shared/strings/app_strings.dart';
import '../../data/models/account_model.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  final AccountModel account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = account.currentBalanceDecimal;
    final isNegative = balance < Decimal.zero;

    return Dismissible(
      key: ValueKey(account.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.archive_outlined, color: theme.colorScheme.onErrorContainer),
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _TypeChip(type: account.type, archived: account.archived),
                    ],
                  ),
                ),
                Text(
                  MoneyFormatter.format(balance),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isNegative ? theme.colorScheme.error : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (_) => onDelete(),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(AppStrings.deleteAction),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.archived});

  final AccountType type;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (type) {
      AccountType.cash => (Icons.payments, AppStrings.accountTypeCash),
      AccountType.debit => (Icons.credit_card, AppStrings.accountTypeDebit),
      AccountType.credit => (Icons.credit_score, AppStrings.accountTypeCredit),
      AccountType.savings => (Icons.savings, AppStrings.accountTypeSavings),
    };

    return Wrap(
      spacing: 8,
      children: [
        Chip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          visualDensity: VisualDensity.compact,
        ),
        if (archived)
          Chip(
            label: const Text(AppStrings.archivedLabel),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
