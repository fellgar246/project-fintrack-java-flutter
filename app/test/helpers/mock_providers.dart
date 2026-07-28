import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/accounts/data/models/account_model.dart';
import 'package:app/features/accounts/providers/accounts_provider.dart';
import 'package:app/features/categories/data/categories_api.dart';
import 'package:app/features/categories/data/models/category_model.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/transactions/data/models/transaction_request.dart';
import 'package:app/features/transactions/data/transactions_api.dart';
import 'package:app/features/transactions/presentation/transaction_form_screen.dart';

/// Fake accounts returned by [accountsControllerProvider] in widget tests.
List<AccountModel> fakeAccounts() {
  final now = DateTime.utc(2026, 7, 1);
  return [
    AccountModel(
      id: 'account-a',
      name: 'Efectivo',
      type: AccountType.cash,
      initialBalance: '1000.00',
      currentBalance: '1000.00',
      archived: false,
      createdAt: now,
    ),
    AccountModel(
      id: 'account-b',
      name: 'Débito',
      type: AccountType.debit,
      initialBalance: '500.00',
      currentBalance: '500.00',
      archived: false,
      createdAt: now,
    ),
  ];
}

List<CategoryModel> fakeExpenseCategories() => const [
      CategoryModel(
        id: 'cat-expense',
        name: 'Comida',
        kind: CategoryKind.expense,
        color: '#FF7043',
        icon: 'restaurant',
        archived: false,
      ),
    ];

List<CategoryModel> fakeIncomeCategories() => const [
      CategoryModel(
        id: 'cat-income',
        name: 'Salario',
        kind: CategoryKind.income,
        color: '#4CAF50',
        icon: 'payments',
        archived: false,
      ),
    ];

/// Records create/update calls without hitting the network.
class RecordingTransactionsApi extends TransactionsApi {
  RecordingTransactionsApi() : super(Dio());

  int createCallCount = 0;
  int updateCallCount = 0;
  TransactionRequest? lastCreateRequest;

  @override
  Future<TransactionModel> create(TransactionRequest request) async {
    createCallCount++;
    lastCreateRequest = request;
    return TransactionModel(
      id: 'new-tx-id',
      type: request.type,
      amount: request.amount,
      date: request.date,
      accountId: request.accountId,
      categoryId: request.categoryId,
      transferAccountId: request.transferAccountId,
      note: request.note,
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );
  }

  @override
  Future<TransactionModel> update(String id, TransactionRequest request) async {
    updateCallCount++;
    return create(request);
  }
}

class FakeCategoriesApi extends CategoriesApi {
  FakeCategoriesApi() : super(Dio());

  @override
  Future<List<CategoryModel>> list({
    CategoryKind? kind,
    bool includeArchived = false,
  }) async {
    if (kind == CategoryKind.income) {
      return fakeIncomeCategories();
    }
    return fakeExpenseCategories();
  }
}

class FakeAccountsController extends AccountsController {
  @override
  Future<List<AccountModel>> build() async => fakeAccounts();
}

/// Wraps [child] with Riverpod overrides for transaction form tests.
Widget buildTestApp({
  required Widget child,
  RecordingTransactionsApi? transactionsApi,
  List<Override> extraOverrides = const [],
}) {
  final api = transactionsApi ?? RecordingTransactionsApi();

  return ProviderScope(
    overrides: [
      transactionsApiProvider.overrideWithValue(api),
      categoriesApiProvider.overrideWithValue(FakeCategoriesApi()),
      accountsControllerProvider.overrideWith(FakeAccountsController.new),
      ...extraOverrides,
    ],
    child: MaterialApp(home: child),
  );
}

Widget buildTransactionFormTestApp({RecordingTransactionsApi? transactionsApi}) {
  return buildTestApp(
    transactionsApi: transactionsApi,
    child: const TransactionFormScreen(),
  );
}
