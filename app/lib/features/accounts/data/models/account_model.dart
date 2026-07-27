import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_model.freezed.dart';

enum AccountType {
  cash,
  debit,
  credit,
  savings,
}

extension AccountTypeApi on AccountType {
  String get apiValue => name.toUpperCase();

  static AccountType fromApi(String value) =>
      AccountType.values.firstWhere((e) => e.apiValue == value);
}

@Freezed(fromJson: false, toJson: false)
class AccountModel with _$AccountModel {
  const AccountModel._();

  const factory AccountModel({
    required String id,
    required String name,
    required AccountType type,
    required String initialBalance,
    required String currentBalance,
    required bool archived,
    required DateTime createdAt,
  }) = _AccountModel;

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountTypeApi.fromApi(json['type'] as String),
        initialBalance: json['initialBalance'] as String,
        currentBalance: json['currentBalance'] as String,
        archived: json['archived'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Decimal get initialBalanceDecimal => Decimal.parse(initialBalance);
  Decimal get currentBalanceDecimal => Decimal.parse(currentBalance);
}
