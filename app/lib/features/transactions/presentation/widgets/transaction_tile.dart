import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/formatters/money_formatter.dart';
import '../../../../shared/icons/material_icon_helper.dart';
import '../../../../shared/strings/app_strings.dart';
import '../../data/models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final TransactionModel transaction;
  final VoidCallback onTap;

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  Color _amountColor(TransactionType type) => switch (type) {
        TransactionType.expense => Colors.red.shade700,
        TransactionType.income => Colors.green.shade700,
        TransactionType.transfer => Colors.blue.shade700,
      };

  String _title() {
    if (transaction.type == TransactionType.transfer) {
      final from = transaction.account?.name ?? '—';
      final to = transaction.transferAccount?.name ?? '—';
      return '$from → $to';
    }
    return transaction.category?.name ?? AppStrings.uncategorized;
  }

  String _signedAmount() {
    final formatted = MoneyFormatter.format(transaction.amountDecimal);
    return switch (transaction.type) {
      TransactionType.expense => '-$formatted',
      TransactionType.income => '+$formatted',
      TransactionType.transfer => formatted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final category = transaction.category;
    final isTransfer = transaction.type == TransactionType.transfer;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isTransfer
            ? Colors.blue.shade100
            : (category != null ? _parseColor(category.color) : Colors.grey.shade400),
        child: Icon(
          isTransfer
              ? Icons.swap_horiz
              : MaterialIconHelper.resolve(category?.icon ?? 'receipt'),
          color: isTransfer ? Colors.blue.shade700 : Colors.white,
        ),
      ),
      title: Text(_title()),
      subtitle: transaction.note != null && transaction.note!.isNotEmpty
          ? Text(transaction.note!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(
        _signedAmount(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _amountColor(transaction.type),
            ),
      ),
    );
  }
}

/// Computes the net amount for a group of transactions on a single day.
Decimal dayNetAmount(List<TransactionModel> transactions) {
  return transactions.fold<Decimal>(Decimal.zero, (sum, tx) {
    return switch (tx.type) {
      TransactionType.expense => sum - tx.amountDecimal,
      TransactionType.income => sum + tx.amountDecimal,
      TransactionType.transfer => sum,
    };
  });
}
