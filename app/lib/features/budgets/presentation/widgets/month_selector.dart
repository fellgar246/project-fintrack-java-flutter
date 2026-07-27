import 'package:flutter/material.dart';

import '../../../../shared/formatters/date_formatter.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onPickMonth,
    required this.canGoNext,
    required this.canGoPrevious,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickMonth;
  final bool canGoNext;
  final bool canGoPrevious;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: canGoPrevious ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mes anterior',
        ),
        TextButton(
          onPressed: onPickMonth,
          child: Text(
            DateFormatter.monthYear(selectedMonth),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: canGoNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Mes siguiente',
        ),
      ],
    );
  }
}

Future<DateTime?> showMonthYearPicker({
  required BuildContext context,
  required DateTime initialMonth,
  required DateTime minMonth,
  required DateTime maxMonth,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      var year = initialMonth.year;
      var month = initialMonth.month;

      return StatefulBuilder(
        builder: (context, setState) {
          final selected = DateTime(year, month);
          final atMin = selected.year == minMonth.year && selected.month == minMonth.month;
          final atMax = selected.year == maxMonth.year && selected.month == maxMonth.month;

          return AlertDialog(
            title: const Text('Elegir mes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: atMin
                          ? null
                          : () => setState(() {
                                if (month == 1) {
                                  year--;
                                  month = 12;
                                } else {
                                  month--;
                                }
                              }),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('$year', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      onPressed: atMax
                          ? null
                          : () => setState(() {
                                if (month == 12) {
                                  year++;
                                  month = 1;
                                } else {
                                  month++;
                                }
                              }),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (index) {
                    final monthNumber = index + 1;
                    final candidate = DateTime(year, monthNumber);
                    final disabled = candidate.isBefore(minMonth) ||
                        candidate.isAfter(maxMonth);
                    final isSelected = monthNumber == month;

                    return ChoiceChip(
                      label: Text(_monthShort(monthNumber)),
                      selected: isSelected,
                      onSelected: disabled
                          ? null
                          : (_) => setState(() => month = monthNumber),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, DateTime(year, month)),
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _monthShort(int month) {
  const names = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  return names[month - 1];
}
