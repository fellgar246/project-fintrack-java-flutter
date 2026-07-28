import 'package:decimal/decimal.dart';

class AccountSummaryItem {
  const AccountSummaryItem({
    required this.accountId,
    required this.name,
    required this.income,
    required this.expense,
    required this.currentBalance,
  });

  final String accountId;
  final String name;
  final String income;
  final String expense;
  final String currentBalance;

  Decimal get currentBalanceDecimal => Decimal.parse(currentBalance);

  factory AccountSummaryItem.fromJson(Map<String, dynamic> json) => AccountSummaryItem(
        accountId: json['accountId'] as String,
        name: json['name'] as String,
        income: json['income'] as String,
        expense: json['expense'] as String,
        currentBalance: json['currentBalance'] as String,
      );
}

class SummaryModel {
  const SummaryModel({
    required this.yearMonth,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.byAccount,
  });

  final String yearMonth;
  final String totalIncome;
  final String totalExpense;
  final String net;
  final List<AccountSummaryItem> byAccount;

  Decimal get totalIncomeDecimal => Decimal.parse(totalIncome);
  Decimal get totalExpenseDecimal => Decimal.parse(totalExpense);
  Decimal get netDecimal => Decimal.parse(net);

  Decimal get totalBalance =>
      byAccount.fold(Decimal.zero, (sum, a) => sum + a.currentBalanceDecimal);

  factory SummaryModel.fromJson(Map<String, dynamic> json) => SummaryModel(
        yearMonth: json['yearMonth'] as String,
        totalIncome: json['totalIncome'] as String,
        totalExpense: json['totalExpense'] as String,
        net: json['net'] as String,
        byAccount: (json['byAccount'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(AccountSummaryItem.fromJson)
            .toList(),
      );
}
