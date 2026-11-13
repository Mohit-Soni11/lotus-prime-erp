import 'package:intl/intl.dart';

class PosAdvanceInvoiceFormatters {
  const PosAdvanceInvoiceFormatters._();

  static final NumberFormat _whole = NumberFormat('#,##,##0', 'en_IN');
  static final NumberFormat _money = NumberFormat('#,##,##0.00', 'en_IN');

  static String money(double amount, {bool alwaysShowPaise = false}) {
    final showPaise =
        alwaysShowPaise || (amount - amount.round()).abs() > 0.005;
    return '₹${showPaise ? _money.format(amount) : _whole.format(amount)}';
  }

  static String weight(double grams) => '${grams.toStringAsFixed(3)} g';

  static bool isRateLocked(String bookingType) =>
      bookingType.trim().toUpperCase() == 'LOCKED';
}
