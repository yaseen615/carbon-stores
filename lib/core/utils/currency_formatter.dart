import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static final _formatterNoDecimal = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  /// Format as ₹1,234.56
  static String format(double amount) => _formatter.format(amount);

  /// Format as ₹1,235 (no decimals)
  static String formatCompact(double amount) => _formatterNoDecimal.format(amount);

  /// Format with sign: +₹500 or -₹200
  static String formatWithSign(double amount) {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${_formatter.format(amount)}';
  }
}
