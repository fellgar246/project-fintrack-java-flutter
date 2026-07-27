import 'package:flutter/material.dart';

import '../../../shared/strings/app_strings.dart';

class AsyncListScaffold extends StatelessWidget {
  const AsyncListScaffold({
    super.key,
    required this.title,
    required this.isLoading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyActionLabel,
    required this.onEmptyAction,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final bool isLoading;
  final Object? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyActionLabel;
  final VoidCallback onEmptyAction;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Card(
            child: SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.genericError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text(AppStrings.retryButton)),
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(emptyTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton(onPressed: onEmptyAction, child: Text(emptyActionLabel)),
            ],
          ),
        ),
      );
    }

    return body;
  }
}
