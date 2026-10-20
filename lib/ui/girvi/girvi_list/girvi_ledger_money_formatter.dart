import 'package:intl/intl.dart';

abstract final class GirviLedgerMoneyFormatter {
  static final NumberFormat _rupees = NumberFormat('#,##,##0', 'en_IN');
  static final NumberFormat _paise = NumberFormat('#,##,##0.00', 'en_IN');

  static String format(double amount) {
    final roundedPaise = (amount * 100).round();
    final formatter = roundedPaise % 100 == 0 ? _rupees : _paise;
    return 'Rs ${formatter.format(roundedPaise / 100)}';
  }
}
