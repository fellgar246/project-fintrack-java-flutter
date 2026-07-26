import 'dart:convert';

import 'package:app/core/network/dio_client.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';
import 'package:app/shared/formatters/money_formatter.dart';

/// In-memory stand-in for `flutter_secure_storage`, which needs a real
/// platform channel that plain widget tests don't have. Pre-seeded with a
/// session so these tests land straight on the dashboard shell — F1.4 added
/// a real auth gate in front of it (see `03-AUTH-FLUTTER.md`).
class _FakeLoggedInTokenStorage extends TokenStorage {
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}

  @override
  Future<String?> readAccess() async => 'fake-access-token';

  @override
  Future<String?> readRefresh() async => 'fake-refresh-token';

  @override
  Future<void> saveUserJson(String userJson) async {}

  @override
  Future<String?> readUserJson() async => jsonEncode({
        'id': 'test-user-id',
        'email': 'test@example.com',
        'name': 'Test User',
        'baseCurrency': 'MXN',
      });

  @override
  Future<void> clear() async {}
}

Widget _loggedInApp() => ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(_FakeLoggedInTokenStorage())],
      child: const FintrackApp(),
    );

void main() {
  testWidgets('App arranca y muestra el dashboard con bottom nav',
      (WidgetTester tester) async {
    await tester.pumpWidget(_loggedInApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('La bottom nav navega entre los 5 placeholders',
      (WidgetTester tester) async {
    await tester.pumpWidget(_loggedInApp());
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
