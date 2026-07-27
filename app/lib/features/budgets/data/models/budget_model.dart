import 'package:decimal/decimal.dart';

class BudgetCategorySummary {
  const BudgetCategorySummary({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String color;
  final String icon;

  factory BudgetCategorySummary.fromJson(Map<String, dynamic> json) =>
      BudgetCategorySummary(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as String,
        icon: json['icon'] as String,
      );
}

enum BudgetStatus {
  ok,
  warning,
  exceeded;

  static BudgetStatus? fromApi(String? value) {
    if (value == null) return null;
    return BudgetStatus.values.firstWhere((e) => e.name.toUpperCase() == value);
  }
}

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.category,
    required this.yearMonth,
    required this.limitAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentUsed,
    required this.status,
  });

  final String? id;
  final BudgetCategorySummary category;
  final String yearMonth;
  final String? limitAmount;
  final String? spentAmount;
  final String? remainingAmount;
  final double? percentUsed;
  final BudgetStatus? status;

  bool get hasBudget => limitAmount != null;

  Decimal? get limitAmountDecimal =>
      limitAmount != null ? Decimal.parse(limitAmount!) : null;

  Decimal get spentAmountDecimal =>
      Decimal.parse(spentAmount ?? '0');

  Decimal? get remainingAmountDecimal =>
      remainingAmount != null ? Decimal.parse(remainingAmount!) : null;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String?,
        category: BudgetCategorySummary.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
        yearMonth: json['yearMonth'] as String,
        limitAmount: json['limitAmount'] as String?,
        spentAmount: json['spentAmount'] as String?,
        remainingAmount: json['remainingAmount'] as String?,
        percentUsed: (json['percentUsed'] as num?)?.toDouble(),
        status: BudgetStatus.fromApi(json['status'] as String?),
      );
}
