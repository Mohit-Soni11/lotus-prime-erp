import 'package:intl/intl.dart';

String dayBookSmartMoney(double amount) => NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    ).format(amount);
