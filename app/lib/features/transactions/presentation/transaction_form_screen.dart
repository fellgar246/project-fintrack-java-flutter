import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/formatters/money_formatter.dart';
import '../../../shared/strings/app_strings.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../categories/data/categories_api.dart';
import '../../categories/data/models/category_model.dart';
import '../data/models/transaction_model.dart';
import '../providers/transaction_form_provider.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/category_picker_grid.dart';

final formCategoriesProvider =
    FutureProvider.autoDispose.family<List<CategoryModel>, CategoryKind>((ref, kind) {
  return ref.read(categoriesApiProvider).list(kind: kind, includeArchived: false);
});

class TransactionFormScreen extends ConsumerWidget {
  const TransactionFormScreen({super.key, this.transactionId});

  final String? transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(transactionFormProvider(transactionId));
    final formController = ref.read(transactionFormProvider(transactionId).notifier);
    final accountsAsync = ref.watch(accountsControllerProvider);

    if (formState.isLoadingExisting) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.editTransactionTitle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final categoryKind = formState.type == TransactionType.income
        ? CategoryKind.income
        : CategoryKind.expense;

    final categoriesAsync = ref.watch(formCategoriesProvider(categoryKind));
    final filteredCategories = categoriesAsync.valueOrNull ?? [];

    final accounts = (accountsAsync.valueOrNull ?? [])
        .where((a) => !a.archived)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          formState.isEditing ? AppStrings.editTransactionTitle : AppStrings.newTransactionTitle,
        ),
        actions: [
          if (formState.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: formState.isSubmitting ? null : () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text(AppStrings.expenseType),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text(AppStrings.incomeType),
                      ),
                      ButtonSegment(
                        value: TransactionType.transfer,
                        label: Text(AppStrings.transferType),
                      ),
                    ],
                    selected: {formState.type},
                    onSelectionChanged: formState.isSubmitting
                        ? null
                        : (selection) => formController.setType(selection.first),
                  ),
                  const SizedBox(height: 24),
                  AmountKeypad(
                    amountRaw: formState.amountRaw,
                    type: formState.type,
                    onDigit: formController.appendDigit,
                    onBackspace: formController.backspace,
                  ),
                  if (formState.fieldErrors['amount'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formState.fieldErrors['amount']!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (formState.type != TransactionType.transfer) ...[
                    Text(AppStrings.categoryLabel, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    CategoryPickerGrid(
                      categories: filteredCategories,
                      selectedId: formState.categoryId,
                      onSelected: formController.setCategoryId,
                      errorText: formState.fieldErrors['categoryId'],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _AccountDropdown(
                    label: AppStrings.accountLabel,
                    accounts: accounts,
                    value: formState.accountId,
                    onChanged: formController.setAccountId,
                    errorText: formState.fieldErrors['accountId'],
                  ),
                  if (formState.type == TransactionType.transfer) ...[
                    const SizedBox(height: 12),
                    _AccountDropdown(
                      label: AppStrings.transferAccountLabel,
                      accounts: accounts,
                      value: formState.transferAccountId,
                      onChanged: formController.setTransferAccountId,
                      errorText: formState.fieldErrors['transferAccountId'] ??
                          (formState.clientError == 'sameAccount'
                              ? AppStrings.sameAccountError
                              : null),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _DateSelector(
                    date: formState.date,
                    onChanged: formController.setDate,
                  ),
                  const SizedBox(height: 16),
                  _NoteField(
                    note: formState.note,
                    onChanged: formController.setNote,
                    errorText: formState.fieldErrors['note'],
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: formState.isValid && !formState.isSubmitting
                    ? () => _submit(context, ref)
                    : null,
                child: formState.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.saveButton),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(transactionFormProvider(transactionId).notifier);

    try {
      await controller.submit();
      if (context.mounted) context.pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.fieldErrors.isNotEmpty) {
        controller.applyFieldErrors(e.fieldErrors);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteTransactionTitle),
        content: const Text(AppStrings.deleteTransactionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final controller = ref.read(transactionFormProvider(transactionId).notifier);
    try {
      await controller.deleteTransaction();
      if (context.mounted) context.pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
    }
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final List<AccountModel> accounts;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
      ),
      items: accounts
          .map(
            (account) => DropdownMenuItem(
              value: account.id,
              child: Text('${account.name} · ${MoneyFormatter.format(account.currentBalanceDecimal)}'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.onChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _yesterday => _today.subtract(const Duration(days: 1));

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.dateLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text(AppStrings.todayLabel),
              selected: _sameDay(date, _today),
              onSelected: (_) => onChanged(_today),
            ),
            ChoiceChip(
              label: const Text(AppStrings.yesterdayLabel),
              selected: _sameDay(date, _yesterday),
              onSelected: (_) => onChanged(_yesterday),
            ),
            ActionChip(
              label: const Text(AppStrings.pickDateLabel),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) onChanged(picked);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({
    required this.note,
    required this.onChanged,
    this.errorText,
  });

  final String note;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note);
  }

  @override
  void didUpdateWidget(covariant _NoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note != widget.note && _controller.text != widget.note) {
      _controller.text = widget.note;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: AppStrings.noteLabel,
        errorText: widget.errorText,
        counterText: '${_controller.text.length}/255',
      ),
      maxLength: 255,
      maxLines: 2,
      onChanged: widget.onChanged,
    );
  }
}
