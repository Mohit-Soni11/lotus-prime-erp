import 'package:intl/intl.dart';

class CustomerMetalPurchaseFormatters {
  CustomerMetalPurchaseFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  static String weight(double value) {
    return '${value.toStringAsFixed(3)} g';
  }

  static String amount(double value) {
    return _currencyFormat.format(value);
  }

  static String rate(double value) {
    if (value <= 0) {
      return 'Not Recorded';
    }
    return '${_currencyFormat.format(value)} / g';
  }

  static String purity(double value) {
    return '${value.toStringAsFixed(2)}%';
  }

  static String date(DateTime value) {
    return _dateFormat.format(value);
  }
}
