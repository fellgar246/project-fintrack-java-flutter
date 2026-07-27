import 'package:intl/intl.dart';

/// Shared date formatting for transaction lists and headers.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _longDay = DateFormat('EEEE d \'de\' MMMM', 'es');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'es');
  static final DateFormat _shortRange = DateFormat('d MMM', 'es');

  static String dayHeader(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final target = _dateOnly(date);
    final yesterday = today.subtract(const Duration(days: 1));

    if (target == today) return 'Hoy';
    if (target == yesterday) return 'Ayer';
    return _capitalize(_longDay.format(target));
  }

  static String monthYear(DateTime date) => _capitalize(_monthYear.format(date));

  static String shortRange(DateTime from, DateTime to) {
    if (from.year == to.year && from.month == to.month) {
      return '${from.day}–${to.day} ${_monthYear.format(from)}';
    }
    return '${_shortRange.format(from)} – ${_shortRange.format(to)}';
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
