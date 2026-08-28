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
  final double paidAmount;
  final double pendingAmount;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final String paymentStatus;
  final String? mobile;
  final DateTime? commitmentDate;
  final String? sellerPhotoPath;
  final bool isReturned;
  final DateTime? returnedAt;
  final bool isTransferredToMelting;
  final DateTime? transferredToMeltingAt;
  final String? meltingBatchNo;

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
    this.paidAmount = 0.0,
    this.pendingAmount = 0.0,
    this.cashPaid = 0.0,
    this.upiPaid = 0.0,
    this.bankPaid = 0.0,
    this.cardPaid = 0.0,
    this.paymentStatus = 'PAID',
    this.mobile,
    this.commitmentDate,
    this.sellerPhotoPath,
    this.isReturned = false,
    this.returnedAt,
    this.isTransferredToMelting = false,
    this.transferredToMeltingAt,
    this.meltingBatchNo,
  });

  double get effectiveRate =>
      rate > 0 || fineWeight <= 0 ? rate : amount / fineWeight;

  bool get isAvailable => !isReturned && !isTransferredToMelting;

  bool get hasSellerPhoto => sellerPhotoPath?.trim().isNotEmpty ?? false;

  String get paymentModeLabel {
    final modes = <String>[
      if (cashPaid > 0.005) 'Cash',
      if (upiPaid > 0.005) 'UPI',
      if (bankPaid > 0.005) 'Bank',
      if (cardPaid > 0.005) 'Card',
    ];
    if (modes.isEmpty) {
      return pendingAmount > 0.005 ? 'Pending' : 'Not Recorded';
    }
    if (modes.length == 1) {
      return modes.single;
    }
    return 'Mixed';
  }

  String get resolvedPaymentStatus {
    if (isReturned) {
      return 'RETURNED';
    }
    if (pendingAmount > 0.005 && paidAmount > 0.005) {
      return 'PARTIAL';
    }
    if (pendingAmount > 0.005) {
      return 'PENDING';
    }
    return paymentStatus.trim().isEmpty ? 'PAID' : paymentStatus;
  }

  CustomerMetalPurchaseEntry copyWith({
    bool? isReturned,
    DateTime? returnedAt,
    bool? isTransferredToMelting,
    DateTime? transferredToMeltingAt,
    String? meltingBatchNo,
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
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      bankPaid: bankPaid,
      cardPaid: cardPaid,
      paymentStatus: paymentStatus,
      mobile: mobile,
      commitmentDate: commitmentDate,
      sellerPhotoPath: sellerPhotoPath,
      isReturned: isReturned ?? this.isReturned,
      returnedAt: returnedAt ?? this.returnedAt,
      isTransferredToMelting:
          isTransferredToMelting ?? this.isTransferredToMelting,
      transferredToMeltingAt:
          transferredToMeltingAt ?? this.transferredToMeltingAt,
      meltingBatchNo: meltingBatchNo ?? this.meltingBatchNo,
    );
  }
}
