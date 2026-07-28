import 'package:decimal/decimal.dart';

class TrendModel {
  const TrendModel({
    required this.yearMonth,
    required this.income,
    required this.expense,
    required this.net,
  });

  final String yearMonth;
  final String income;
  final String expense;
  final String net;

  Decimal get incomeDecimal => Decimal.parse(income);
  Decimal get expenseDecimal => Decimal.parse(expense);
  Decimal get netDecimal => Decimal.parse(net);

  factory TrendModel.fromJson(Map<String, dynamic> json) => TrendModel(
        yearMonth: json['yearMonth'] as String,
        income: json['income'] as String,
        expense: json['expense'] as String,
        net: json['net'] as String,
      );
}
