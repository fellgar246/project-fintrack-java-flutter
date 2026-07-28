import 'package:app/features/budgets/data/models/budget_model.dart';
import 'package:app/features/budgets/presentation/widgets/budget_card.dart';
import 'package:app/features/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BudgetModel _budget(double percent, BudgetStatus status) {
  return BudgetModel(
    id: 'budget-1',
    category: const BudgetCategorySummary(
      id: 'cat-1',
      name: 'Comida',
      color: '#FF7043',
      icon: 'restaurant',
    ),
    yearMonth: '2026-07',
    limitAmount: '1000.00',
    spentAmount: '500.00',
    remainingAmount: '500.00',
    percentUsed: percent,
    status: status,
  );
}

void main() {
  testWidgets('50% → status ok (verde)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetProgressBar(percentUsed: 50, status: BudgetStatus.ok),
        ),
      ),
    );

    final bar = tester.widget<BudgetProgressBar>(find.byType(BudgetProgressBar));
    expect(bar.status, BudgetStatus.ok);
    expect(bar.percentUsed, 50);
  });

  testWidgets('85% → status warning (ámbar)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetProgressBar(percentUsed: 85, status: BudgetStatus.warning),
        ),
      ),
    );

    final bar = tester.widget<BudgetProgressBar>(find.byType(BudgetProgressBar));
    expect(bar.status, BudgetStatus.warning);
  });

  testWidgets('100% y 120% → status exceeded (rojo)', (tester) async {
    for (final percent in [100.0, 120.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetProgressBar(percentUsed: percent, status: BudgetStatus.exceeded),
          ),
        ),
      );

      final bar = tester.widget<BudgetProgressBar>(find.byType(BudgetProgressBar));
      expect(bar.status, BudgetStatus.exceeded);
    }
  });

  testWidgets('El porcentaje aparece como texto en BudgetCard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetCard(
            budget: _budget(75, BudgetStatus.warning),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('75%'), findsOneWidget);
  });
}
