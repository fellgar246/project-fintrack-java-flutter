import 'package:decimal/decimal.dart';

enum TransactionType {
  expense,
  income,
  transfer,
}

extension TransactionTypeApi on TransactionType {
  String get apiValue => name.toUpperCase();

  static TransactionType fromApi(String value) =>
      TransactionType.values.firstWhere((e) => e.apiValue == value);
}

class TransactionAccountSummary {
  const TransactionAccountSummary({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory TransactionAccountSummary.fromJson(Map<String, dynamic> json) =>
      TransactionAccountSummary(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class TransactionCategorySummary {
  const TransactionCategorySummary({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String color;
  final String icon;

  factory TransactionCategorySummary.fromJson(Map<String, dynamic> json) =>
      TransactionCategorySummary(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as String,
        icon: json['icon'] as String,
      );
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.categoryId,
    this.transferAccountId,
    this.note,
    this.account,
    this.category,
    this.transferAccount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final TransactionType type;
  final String amount;
  final DateTime date;
  final String accountId;
  final String? categoryId;
  final String? transferAccountId;
  final String? note;
  final TransactionAccountSummary? account;
  final TransactionCategorySummary? category;
  final TransactionAccountSummary? transferAccount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Decimal get amountDecimal => Decimal.parse(amount);

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        type: TransactionTypeApi.fromApi(json['type'] as String),
        amount: json['amount'] as String,
        date: DateTime.parse(json['date'] as String),
        accountId: json['accountId'] as String,
        categoryId: json['categoryId'] as String?,
        transferAccountId: json['transferAccountId'] as String?,
        note: json['note'] as String?,
        account: json['account'] == null
            ? null
            : TransactionAccountSummary.fromJson(json['account'] as Map<String, dynamic>),
        category: json['category'] == null
            ? null
            : TransactionCategorySummary.fromJson(json['category'] as Map<String, dynamic>),
        transferAccount: json['transferAccount'] == null
            ? null
            : TransactionAccountSummary.fromJson(json['transferAccount'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
