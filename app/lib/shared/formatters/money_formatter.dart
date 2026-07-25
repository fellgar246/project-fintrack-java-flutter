import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Formatea montos monetarios en es_MX, ej. `Decimal.parse('1234.5')` -> `$1,234.50`.
/// Nunca se formatea moneda inline en widgets; siempre a través de este helper.
class MoneyFormatter {
  MoneyFormatter._();

  static final NumberFormat _format = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
  );

  static String format(Decimal amount) {
    return _format.format(amount.toDouble());
  }
}
