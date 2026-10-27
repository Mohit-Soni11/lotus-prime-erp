import 'package:intl/intl.dart';

class CustomerListNumberFormat {
  CustomerListNumberFormat._();

  static final NumberFormat _count = NumberFormat.decimalPattern('en_IN');
  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  static String count(int value) => _count.format(value);

  static String money(double value) =>
      _money.format(value.abs() < 0.005 ? 0 : value);
}
