import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _monthYearFormat = DateFormat('MMMM yyyy');
  static final _shortDateFormat = DateFormat('dd/MM/yy');

  /// "02 Apr 2026"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// "01:30 PM"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// "02 Apr 2026, 01:30 PM"
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// "April 2026"
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// "02/04/26"
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  /// "Today", "Yesterday", or date
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return formatDate(date);
  }

  /// Start of today
  static DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Start of month
  static DateTime get startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
}
