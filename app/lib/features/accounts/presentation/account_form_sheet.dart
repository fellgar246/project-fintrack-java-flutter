import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/strings/app_strings.dart';
import '../data/models/account_model.dart';
import '../providers/accounts_provider.dart';

Future<void> showAccountFormSheet(
  BuildContext context, {
  AccountModel? account,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AccountFormSheet(account: account),
  );
}

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.account});

  final AccountModel? account;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late AccountType _type;
  bool _submitting = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.account?.initialBalance ?? '0',
    );
    _type = widget.account?.type ?? AccountType.debit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final controller = ref.read(accountsControllerProvider.notifier);
      final name = _nameController.text.trim();
      final balance = _balanceController.text.trim();

      if (_isEditing) {
        await controller.updateAccount(
          id: widget.account!.id,
          name: name,
          type: _type,
          initialBalance: balance,
        );
      } else {
        await controller.create(name: name, type: _type, initialBalance: balance);
      }

      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.isConflict ? AppStrings.accountNameConflict : e.detail;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? AppStrings.editAccountTitle : AppStrings.newAccountTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: AppStrings.accountNameLabel),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? AppStrings.nameRequired : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: AppStrings.accountTypeLabel),
              items: AccountType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_typeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: _submitting ? null : (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(labelText: AppStrings.initialBalanceLabel),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.amountRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? AppStrings.saveButton : AppStrings.createButton),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(AccountType type) => switch (type) {
        AccountType.cash => AppStrings.accountTypeCash,
        AccountType.debit => AppStrings.accountTypeDebit,
        AccountType.credit => AppStrings.accountTypeCredit,
        AccountType.savings => AppStrings.accountTypeSavings,
      };
}
