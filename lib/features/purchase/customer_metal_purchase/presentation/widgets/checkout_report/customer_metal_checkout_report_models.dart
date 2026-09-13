part of '../../screens/customer_metal_checkout_report_screen.dart';

class _CheckoutMonthSummary {
  final int month;
  final List<CustomerMetalPurchaseEntry> entries;

  const _CheckoutMonthSummary({
    required this.month,
    required this.entries,
  });

  bool get hasData => entries.isNotEmpty;

  int get lineCount => entries.length;

  int get batchCount {
    return entries
        .map((entry) => entry.meltingBatchNo?.trim().toUpperCase() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
  }

  double get netWeight =>
      entries.fold(0, (sum, entry) => sum + entry.netWeight);

  double get fineWeight =>
      entries.fold(0, (sum, entry) => sum + entry.fineWeight);

  double get amount => entries.fold(0, (sum, entry) => sum + entry.amount);

  List<_CheckoutMetalSummary> get visibleMetalSummaries {
    return [
      for (final metal in CustomerMetalPurchaseMetal.values)
        _CheckoutMetalSummary(
          metal: metal,
          entries: entries
              .where((entry) =>
                  entry.metalType.trim().toUpperCase() == metal.storageValue)
              .toList(growable: false),
        ),
    ].where((summary) => summary.hasData).toList(growable: false);
  }
}

class _CheckoutMetalSummary {
  final CustomerMetalPurchaseMetal metal;
  final List<CustomerMetalPurchaseEntry> entries;

  const _CheckoutMetalSummary({
    required this.metal,
    required this.entries,
  });

  bool get hasData => entries.isNotEmpty;

  int get lineCount => entries.length;

  int get batchCount {
    return entries
        .map((entry) => entry.meltingBatchNo?.trim().toUpperCase() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
  }

  double get netWeight =>
      entries.fold(0, (sum, entry) => sum + entry.netWeight);

  double get fineWeight =>
      entries.fold(0, (sum, entry) => sum + entry.fineWeight);

  double get amount => entries.fold(0, (sum, entry) => sum + entry.amount);

  double get paidAmount =>
      entries.fold(0, (sum, entry) => sum + entry.paidAmount);

  double get pendingAmount =>
      entries.fold(0, (sum, entry) => sum + entry.pendingAmount);
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

String _monthShortName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

String _slug(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

final TextStyle _titleStyle = GoogleFonts.inter(
  fontSize: 22,
  fontWeight: FontWeight.w900,
  color: Colors.black,
  letterSpacing: 0,
);

final TextStyle _subtitleStyle = GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: Colors.black,
  letterSpacing: 0,
);

final TextStyle _buttonTextStyle = GoogleFonts.inter(
  fontSize: 15,
  fontWeight: FontWeight.w900,
  color: Colors.black,
  letterSpacing: 0,
);

final TextStyle _cardTitleStyle = GoogleFonts.inter(
  fontSize: 18,
  fontWeight: FontWeight.w900,
  color: Colors.black,
  letterSpacing: 0,
);

final TextStyle _cardSubTitleStyle = GoogleFonts.inter(
  fontSize: 13,
  fontWeight: FontWeight.w900,
  color: Colors.black,
  letterSpacing: 0,
);

final TextStyle _metricLabelStyle = GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w900,
  color: Colors.black,
  letterSpacing: 0,
);

final TextStyle _pillLabelStyle = GoogleFonts.inter(
  fontSize: 11,
  fontWeight: FontWeight.w900,
  color: Colors.black,
  letterSpacing: 0,
);

final TextStyle _pillValueStyle = GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w900,
  color: Colors.black,
  letterSpacing: 0,
);
