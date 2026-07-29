class CustomerMetalPurchaseEntry {
  final int id;
  final int? customerId;
  final int sourceDocumentId;
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
  final bool isReturned;
  final DateTime? returnedAt;

  const CustomerMetalPurchaseEntry({
    required this.id,
    required this.customerId,
    required this.sourceDocumentId,
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
    this.isReturned = false,
    this.returnedAt,
  });

  double get effectiveRate =>
      rate > 0 || fineWeight <= 0 ? rate : amount / fineWeight;

  CustomerMetalPurchaseEntry copyWith({
    bool? isReturned,
    DateTime? returnedAt,
  }) {
    return CustomerMetalPurchaseEntry(
      id: id,
      customerId: customerId,
      sourceDocumentId: sourceDocumentId,
      date: date,
      source: source,
      referenceNo: referenceNo,
      customerName: customerName,
      metalType: metalType,
      itemDescription: itemDescription,
      grossWeight: grossWeight,
      netWeight: netWeight,
      purity: purity,
      fineWeight: fineWeight,
      rate: rate,
      amount: amount,
      isReturned: isReturned ?? this.isReturned,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }
}
