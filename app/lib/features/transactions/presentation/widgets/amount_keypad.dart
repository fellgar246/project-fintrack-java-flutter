import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/formatters/money_formatter.dart';
import '../../data/models/transaction_model.dart';

class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.amountRaw,
    required this.type,
    required this.onDigit,
    required this.onBackspace,
  });

  final String amountRaw;
  final TransactionType type;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  Color get _amountColor => switch (type) {
        TransactionType.expense => Colors.red.shade700,
        TransactionType.income => Colors.green.shade700,
        TransactionType.transfer => Colors.blue.shade700,
      };

  String get _displayAmount {
    try {
      final normalized = amountRaw.endsWith('.')
          ? '${amountRaw}0'
          : amountRaw.contains('.')
              ? amountRaw
              : '$amountRaw.00';
      final parts = normalized.split('.');
      final decimals = (parts.length > 1 ? parts[1] : '').padRight(2, '0').substring(0, 2);
      final value = Decimal.parse('${parts[0]}.$decimals');
      return MoneyFormatter.format(value);
    } catch (_) {
      return MoneyFormatter.format(Decimal.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _displayAmount,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _amountColor,
              ),
        ),
        const SizedBox(height: 16),
        _KeypadGrid(
          onDigit: onDigit,
          onBackspace: onBackspace,
        ),
      ],
    );
  }
}

class _KeypadGrid extends StatelessWidget {
  const _KeypadGrid({
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              return SizedBox(
                width: 72,
                height: 52,
                child: FilledButton.tonal(
                  onPressed: () {
                    if (key == '⌫') {
                      onBackspace();
                    } else {
                      onDigit(key);
                    }
                  },
                  child: Text(key, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
