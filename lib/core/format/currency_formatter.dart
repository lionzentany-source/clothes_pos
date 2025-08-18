import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(
    double amount, {
    String currency = 'LYD',
    String locale = 'ar',
  }) {
    // Map common codes to symbols (Intl doesn't know all by default)
    final symbol = _symbolFor(currency);
    final fmt = NumberFormat.currency(
      locale: locale,
      name: currency,
      symbol: symbol,
    );
    return fmt.format(amount);
  }

  static String _symbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'LYD':
        return 'د.ل'; // دينار ليبي
      case 'USD':
        return r'\$';
      case 'EUR':
        return '€';
      default:
        return code.toUpperCase();
    }
  }
}
