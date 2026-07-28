import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_providers.dart';

/// Minimal Material shell for widget tests with shared provider overrides.
class TestApp extends StatelessWidget {
  const TestApp({super.key, required this.child, this.overrides = const []});

  final Widget child;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );
  }
}

/// Transaction form under test with mocked dependencies.
class TransactionFormTestApp extends StatelessWidget {
  const TransactionFormTestApp({super.key, this.transactionsApi});

  final RecordingTransactionsApi? transactionsApi;

  @override
  Widget build(BuildContext context) {
    return buildTransactionFormTestApp(transactionsApi: transactionsApi);
  }
}
