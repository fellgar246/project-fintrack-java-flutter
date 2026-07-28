import 'package:app/features/accounts/providers/accounts_provider.dart';
import 'package:app/features/categories/data/categories_api.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/data/transactions_api.dart';
import 'package:app/features/transactions/presentation/transaction_form_screen.dart';
import 'package:app/features/transactions/providers/transaction_form_provider.dart';
import 'package:app/shared/strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/mock_providers.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es');
  });

  Future<ProviderContainer> pumpForm(WidgetTester tester, {RecordingTransactionsApi? api}) async {
    await tester.pumpWidget(TransactionFormTestApp(transactionsApi: api));
    await tester.pumpAndSettle();
    final element = tester.element(find.byType(TransactionFormScreen));
    return ProviderScope.containerOf(element);
  }

  testWidgets('Se renderiza con providers mockeados', (tester) async {
    await tester.pumpWidget(const TransactionFormTestApp());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.newTransactionTitle), findsOneWidget);
    expect(find.text(AppStrings.saveButton), findsOneWidget);
  });

  testWidgets('Monto 0 → botón guardar deshabilitado', (tester) async {
    await tester.pumpWidget(const TransactionFormTestApp());
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, AppStrings.saveButton),
    );
    expect(button.onPressed, isNull);
  });

  test('AmountInput: no permite 3 decimales ni dos puntos', () {
    expect(AmountInput.appendDigit('10.25', '5'), '10.25');
    expect(AmountInput.appendDigit('10', '.'), '10.');
    expect(AmountInput.appendDigit('10.', '.'), '10.');
  });

  testWidgets('Transferencia oculta categoría y muestra cuenta destino', (tester) async {
    await tester.pumpWidget(const TransactionFormTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.transferType));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.categoryLabel), findsNothing);
    expect(find.text(AppStrings.transferAccountLabel), findsOneWidget);
  });

  testWidgets('Origen = destino → mensaje de error', (tester) async {
    final container = await pumpForm(tester);
    final notifier = container.read(transactionFormProvider(null).notifier);

    notifier.setType(TransactionType.transfer);
    notifier.setAccountId('account-a');
    notifier.setTransferAccountId('account-a');
    await tester.pump();

    expect(find.text(AppStrings.sameAccountError), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, AppStrings.saveButton),
    );
    expect(button.onPressed, isNull);
  });

  test('Guardar válido llama al repositorio mock una sola vez', () async {
    final api = RecordingTransactionsApi();
    final container = ProviderContainer(
      overrides: [
        transactionsApiProvider.overrideWithValue(api),
        categoriesApiProvider.overrideWithValue(FakeCategoriesApi()),
        accountsControllerProvider.overrideWith(FakeAccountsController.new),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(transactionFormProvider(null).notifier);
    notifier.appendDigit('5');
    notifier.appendDigit('0');
    notifier.setCategoryId('cat-expense');
    notifier.setAccountId('account-a');

    await notifier.submit();

    expect(api.createCallCount, 1);
    expect(api.lastCreateRequest?.amount, '50.00');
  });
}
