import 'package:app/shared/formatters/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_MX');
  });

  test('1234.5 → \$1,234.50', () {
    expect(MoneyFormatter.format(Decimal.parse('1234.5')), r'$1,234.50');
  });

  test('0 → \$0.00', () {
    expect(MoneyFormatter.format(Decimal.zero), r'$0.00');
  });

  test('-500 → -\$500.00', () {
    expect(MoneyFormatter.format(Decimal.parse('-500')), r'-$500.00');
  });

  test('1000000 → \$1,000,000.00', () {
    expect(MoneyFormatter.format(Decimal.parse('1000000')), r'$1,000,000.00');
  });

  test('0.1 + 0.2 con Decimal → \$0.30 exacto', () {
    final sum = Decimal.parse('0.1') + Decimal.parse('0.2');
    expect(MoneyFormatter.format(sum), r'$0.30');
  });
}
