import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';
import 'package:app/shared/formatters/money_formatter.dart';

void main() {
  testWidgets('App arranca y muestra el dashboard con bottom nav',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FintrackApp()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('La bottom nav navega entre los 5 placeholders',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FintrackApp()));
    await tester.pumpAndSettle();

    const destinations = {
      'Transacciones': 'Transacciones',
      'Presupuestos': 'Presupuestos',
      'Reportes': 'Reportes',
      'Ajustes': 'Ajustes',
    };

    for (final label in destinations.keys) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
      expect(find.text(destinations[label]!), findsWidgets);
    }

    await tester.tap(find.widgetWithText(NavigationDestination, 'Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
  });

  test('MoneyFormatter formatea en es_MX', () {
    expect(MoneyFormatter.format(Decimal.parse('1234.5')), r'$1,234.50');
  });
}
