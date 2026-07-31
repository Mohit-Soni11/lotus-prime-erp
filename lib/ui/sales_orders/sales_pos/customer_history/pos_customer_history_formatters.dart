class PosCustomerHistoryFormatters {
  const PosCustomerHistoryFormatters._();

  static String amount(double value) {
    if (value >= 100000) return 'Rs ${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return 'Rs ${(value / 1000).toStringAsFixed(1)}K';
    return 'Rs ${value.toStringAsFixed(0)}';
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
