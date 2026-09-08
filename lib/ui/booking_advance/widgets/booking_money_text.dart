import 'package:intl/intl.dart';

class BookingMoneyText {
  const BookingMoneyText._();

  static const String symbol = '\u20B9';

  static String whole(num value) {
    return '$symbol ${NumberFormat('#,##,###', 'en_IN').format(value.round())}';
  }

  static String decimal(num value) {
    return '$symbol${NumberFormat('#,##,##0.00', 'en_IN').format(value)}';
  }

  static String compact(num value) {
    final rounded = value.roundToDouble();
    final hasDecimal = (value - rounded).abs() >= 0.005;
    final format = hasDecimal ? '#,##,##0.##' : '#,##,###';
    return '$symbol${NumberFormat(format, 'en_IN').format(value)}';
  }
}
