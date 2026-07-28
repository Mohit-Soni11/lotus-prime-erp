class CustomerMetalPurchaseEntry {
  final int id;
  final DateTime date;
  final String source;
  final String referenceNo;
  final String customerName;
  final String metalType;
  final String itemDescription;
  final double grossWeight;
  final double netWeight;
  final double purity;
  final double fineWeight;
  final double rate;
  final double amount;

  const CustomerMetalPurchaseEntry({
    required this.id,
    required this.date,
    required this.source,
    required this.referenceNo,
    required this.customerName,
    required this.metalType,
    required this.itemDescription,
    required this.grossWeight,
    required this.netWeight,
    required this.purity,
    required this.fineWeight,
    required this.rate,
    required this.amount,
  });

  double get effectiveRate =>
      rate > 0 || fineWeight <= 0 ? rate : amount / fineWeight;
}
