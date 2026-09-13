import 'package:intl/intl.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';

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

  static String batchNumber(String value) {
    final normalized = value.trim().toUpperCase();
    final modern = RegExp(r'^MT-\d{2}-\d{2}(?:-\d+)?$');
    if (modern.hasMatch(normalized)) {
      return normalized;
    }

    final melt = RegExp(r'^MELT-(\d{2})(\d{2})(\d{2})(?:-(\d+))?$')
        .firstMatch(normalized);
    if (melt != null) {
      final month = melt.group(2)!;
      final year = melt.group(3)!;
      final sequence = melt.group(4);
      return sequence == null ? 'MT-$month-$year' : 'MT-$month-$year-$sequence';
    }

    final legacy = RegExp(r'^CMB-[A-Z]+-(\d{4})(\d{2})(\d{2})-\d{6}$')
        .firstMatch(normalized);
    if (legacy == null) {
      return value;
    }

    final year = legacy.group(1)!.substring(2);
    final month = legacy.group(2)!;
    return 'MT-$month-$year';
  }

  static String checkoutItemLabel(CustomerMetalPurchaseEntry entry) {
    final description = entry.itemDescription.trim();
    if (description.isEmpty) {
      return entry.metalType;
    }

    final lowerDescription = description.toLowerCase();
    if (!lowerDescription.contains('return melting')) {
      return description;
    }

    final itemName = description.split('|').first.trim();
    if (itemName.isEmpty || itemName.toLowerCase() == 'return melting') {
      return 'Direct Melting';
    }
    return '$itemName | Direct Melting';
  }
}
