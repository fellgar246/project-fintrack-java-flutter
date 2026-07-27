import 'transaction_model.dart';

class TransactionRequest {
  const TransactionRequest({
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.categoryId,
    this.transferAccountId,
    this.note,
  });

  final TransactionType type;
  final String amount;
  final DateTime date;
  final String accountId;
  final String? categoryId;
  final String? transferAccountId;
  final String? note;

  Map<String, dynamic> toJson() => {
        'type': type.apiValue,
        'amount': amount,
        'date': _formatDate(date),
        'accountId': accountId,
        'categoryId': categoryId,
        'transferAccountId': transferAccountId,
        'note': note?.isEmpty ?? true ? null : note,
      };

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
