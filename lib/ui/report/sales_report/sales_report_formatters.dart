import 'package:intl/intl.dart';

String salesReportMoney(double value) {
  final decimals = value == value.roundToDouble() ? 0 : 2;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: decimals,
  ).format(value);
}

String salesReportWeight(double value) {
  final decimals = value == value.roundToDouble() ? 0 : 3;
  return '${value.toStringAsFixed(decimals)} g';
}

String salesReportDate(DateTime value) {
  return DateFormat('dd MMM yyyy').format(value).toUpperCase();
}

String salesReportDateTime(DateTime value) {
  return DateFormat('dd MMM yyyy, hh:mm a').format(value).toUpperCase();
}
