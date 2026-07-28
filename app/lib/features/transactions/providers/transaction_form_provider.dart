import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/providers/accounts_provider.dart';
import '../../budgets/providers/budgets_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/models/transaction_model.dart';
import '../data/models/transaction_request.dart';
import '../data/transactions_api.dart';
import 'transactions_list_provider.dart';

/// Builds amount strings digit-by-digit — never passes through [double].
class AmountInput {
  AmountInput._();

  static String appendDigit(String current, String digit) {
    var value = current.isEmpty ? '0' : current;

    if (digit == '.') {
      if (value.contains('.')) return value;
      return '$value.';
    }

    if (value == '0') {
      return digit;
    }

    final dotIndex = value.indexOf('.');
    if (dotIndex >= 0 && value.length - dotIndex - 1 >= 2) {
      return value;
    }

    return '$value$digit';
  }

  static String backspace(String current) {
    if (current.isEmpty || current == '0') return '0';
    final trimmed = current.substring(0, current.length - 1);
    return trimmed.isEmpty ? '0' : trimmed;
  }

  static String normalizeForApi(String raw) {
    var value = raw.isEmpty ? '0' : raw;
    if (value.endsWith('.')) {
      value = '${value}0';
    }
    if (!value.contains('.')) {
      value = '$value.00';
    } else {
      final parts = value.split('.');
      final decimals = parts[1].padRight(2, '0').substring(0, 2);
      value = '${parts[0]}.$decimals';
    }
    return value;
  }

  static bool isPositive(String raw) {
    try {
      return Decimal.parse(normalizeForApi(raw)) > Decimal.zero;
    } catch (_) {
      return false;
    }
  }
}

class TransactionFormState {
  const TransactionFormState({
    this.transactionId,
    this.isLoadingExisting = false,
    this.type = TransactionType.expense,
    this.amountRaw = '0',
    this.accountId,
    this.transferAccountId,
    this.categoryId,
    required this.date,
    this.note = '',
    this.isSubmitting = false,
    this.fieldErrors = const {},
    this.savedCategoryId,
    this.savedTransferAccountId,
  });

  final String? transactionId;
  final bool isLoadingExisting;
  final TransactionType type;
  final String amountRaw;
  final String? accountId;
  final String? transferAccountId;
  final String? categoryId;
  final DateTime date;
  final String note;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;

  /// Preserved when switching away from expense/income so values aren't lost.
  final String? savedCategoryId;

  /// Preserved when switching away from transfer.
  final String? savedTransferAccountId;

  bool get isEditing => transactionId != null;

  bool get isValid {
    if (!AmountInput.isPositive(amountRaw)) return false;
    if (accountId == null) return false;
    if (type == TransactionType.transfer) {
      if (transferAccountId == null) return false;
      if (accountId == transferAccountId) return false;
    } else {
      if (categoryId == null) return false;
    }
    return true;
  }

  String? get clientError {
    if (type == TransactionType.transfer &&
        accountId != null &&
        transferAccountId != null &&
        accountId == transferAccountId) {
      return 'sameAccount';
    }
    return null;
  }

  TransactionFormState copyWith({
    String? transactionId,
    bool? isLoadingExisting,
    TransactionType? type,
    String? amountRaw,
    String? accountId,
    String? transferAccountId,
    String? categoryId,
    DateTime? date,
    String? note,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    String? savedCategoryId,
    String? savedTransferAccountId,
    bool clearFieldErrors = false,
  }) {
    return TransactionFormState(
      transactionId: transactionId ?? this.transactionId,
      isLoadingExisting: isLoadingExisting ?? this.isLoadingExisting,
      type: type ?? this.type,
      amountRaw: amountRaw ?? this.amountRaw,
      accountId: accountId ?? this.accountId,
      transferAccountId: transferAccountId ?? this.transferAccountId,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      fieldErrors: clearFieldErrors ? const {} : (fieldErrors ?? this.fieldErrors),
      savedCategoryId: savedCategoryId ?? this.savedCategoryId,
      savedTransferAccountId: savedTransferAccountId ?? this.savedTransferAccountId,
    );
  }
}

class TransactionFormController extends AutoDisposeFamilyNotifier<TransactionFormState, String?> {
  @override
  TransactionFormState build(String? transactionId) {
    if (transactionId != null) {
      Future.microtask(() => _loadExisting(transactionId));
      return TransactionFormState(
        transactionId: transactionId,
        isLoadingExisting: true,
        date: DateTime.now(),
      );
    }
    return TransactionFormState(date: _today());
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _loadExisting(String id) async {
    try {
      final tx = await ref.read(transactionsApiProvider).getById(id);
      state = TransactionFormState(
        transactionId: id,
        type: tx.type,
        amountRaw: _amountToRaw(tx.amount),
        accountId: tx.accountId,
        transferAccountId: tx.transferAccountId,
        categoryId: tx.categoryId,
        savedCategoryId: tx.categoryId,
        savedTransferAccountId: tx.transferAccountId,
        date: DateTime(tx.date.year, tx.date.month, tx.date.day),
        note: tx.note ?? '',
      );
    } catch (_) {
      state = state.copyWith(isLoadingExisting: false);
      rethrow;
    }
  }

  String _amountToRaw(String amount) {
    if (amount.endsWith('.00')) {
      return amount.substring(0, amount.length - 3);
    }
    return amount;
  }

  void setType(TransactionType type) {
    if (type == state.type) return;

    if (state.type == TransactionType.transfer && type != TransactionType.transfer) {
      state = state.copyWith(
        type: type,
        savedTransferAccountId: state.transferAccountId,
        transferAccountId: null,
        categoryId: state.savedCategoryId ?? state.categoryId,
        clearFieldErrors: true,
      );
    } else if (state.type != TransactionType.transfer && type == TransactionType.transfer) {
      state = state.copyWith(
        type: type,
        savedCategoryId: state.categoryId,
        categoryId: null,
        transferAccountId: state.savedTransferAccountId,
        clearFieldErrors: true,
      );
    } else {
      state = state.copyWith(type: type, clearFieldErrors: true);
    }
  }

  void appendDigit(String digit) {
    state = state.copyWith(
      amountRaw: AmountInput.appendDigit(state.amountRaw, digit),
      clearFieldErrors: true,
    );
  }

  void backspace() {
    state = state.copyWith(
      amountRaw: AmountInput.backspace(state.amountRaw),
      clearFieldErrors: true,
    );
  }

  void setAccountId(String? id) {
    state = state.copyWith(accountId: id, clearFieldErrors: true);
  }

  void setTransferAccountId(String? id) {
    state = state.copyWith(transferAccountId: id, clearFieldErrors: true);
  }

  void setCategoryId(String? id) {
    state = state.copyWith(categoryId: id, clearFieldErrors: true);
  }

  void setDate(DateTime date) {
    state = state.copyWith(
      date: DateTime(date.year, date.month, date.day),
      clearFieldErrors: true,
    );
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  TransactionRequest _buildRequest() {
    return TransactionRequest(
      type: state.type,
      amount: AmountInput.normalizeForApi(state.amountRaw),
      date: state.date,
      accountId: state.accountId!,
      categoryId: state.type == TransactionType.transfer ? null : state.categoryId,
      transferAccountId: state.type == TransactionType.transfer ? state.transferAccountId : null,
      note: state.note.trim(),
    );
  }

  Future<void> submit() async {
    if (!state.isValid || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true, clearFieldErrors: true);

    try {
      final api = ref.read(transactionsApiProvider);
      final request = _buildRequest();

      if (state.isEditing) {
        await api.update(state.transactionId!, request);
      } else {
        await api.create(request);
      }

      ref.invalidate(transactionsListProvider);
      ref.invalidate(accountsControllerProvider);
      invalidateVisibleBudgets(ref);
      invalidateDashboard(ref);

      state = state.copyWith(isSubmitting: false);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  void applyFieldErrors(Map<String, String> errors) {
    state = state.copyWith(fieldErrors: errors);
  }

  Future<void> deleteTransaction() async {
    if (state.transactionId == null || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      await ref.read(transactionsApiProvider).delete(state.transactionId!);
      ref.invalidate(transactionsListProvider);
      ref.invalidate(accountsControllerProvider);
      invalidateVisibleBudgets(ref);
      invalidateDashboard(ref);
      state = state.copyWith(isSubmitting: false);
    } on Exception catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final transactionFormProvider = AutoDisposeNotifierProviderFamily<
    TransactionFormController, TransactionFormState, String?>(
  TransactionFormController.new,
);
