import 'package:intl/intl.dart';

class PosCustomerHistoryFormatters {
  const PosCustomerHistoryFormatters._();

  static final NumberFormat _amountFormat = NumberFormat(
    '#,##,##0.00',
    'en_IN',
  );

  static String amount(double value) {
    return 'Rs ${_amountFormat.format(value.abs())}';
  }

  static String lastVisit(List<dynamic> bills) {
    if (bills.isEmpty) return 'First Visit';

    final days = DateTime.now().difference(bills.first.billDate).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 30) return '$days days ago';
    if (days < 365) return '${(days / 30).floor()} months ago';

    final years = (days / 365).floor();
    final months = ((days % 365) / 30).floor();
    return months > 0 ? '$years yr $months mo' : '$years yr ago';
  }
}
