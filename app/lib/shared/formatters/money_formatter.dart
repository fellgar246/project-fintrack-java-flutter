import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Formats money amounts in es_MX, e.g. `Decimal.parse('1234.5')` -> `$1,234.50`.
/// Currency is never formatted inline in widgets; always through this helper.
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
