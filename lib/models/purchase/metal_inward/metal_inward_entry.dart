class MetalInwardEntry {
  final int id;
  final DateTime date;
  final String source; // 'Trade-In (Sales)' or 'Purchase (Customer)'
  final String referenceNo; // Invoice No or Voucher No
  final String customerName;
  final String metalType;
  final String itemDescription;
  final double grossWeight;
  final double netWeight;
  final double purity;
  final double fineWeight;
  final double amount;

  const MetalInwardEntry({
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
    required this.amount,
  });
}
