class CustomerMetalPurchaseVoucherDetail {
  final int id;
  final String voucherNo;
  final int sequenceNo;
  final int? customerId;
  final String partyName;
  final String? mobile;
  final String? city;
  final String? panNumber;
  final DateTime createdAt;
  final String taxType;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double grandTotal;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final double totalPaid;
  final double balanceDue;
  final String paymentStatus;
  final DateTime? promiseDate;
  final String? sellerPhotoPath;
  final List<CustomerMetalPurchaseVoucherLine> lines;

  const CustomerMetalPurchaseVoucherDetail({
    required this.id,
    required this.voucherNo,
    required this.sequenceNo,
    required this.customerId,
    required this.partyName,
    required this.mobile,
    required this.city,
    required this.panNumber,
    required this.createdAt,
    required this.taxType,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.grandTotal,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankPaid,
    required this.cardPaid,
    required this.totalPaid,
    required this.balanceDue,
    required this.paymentStatus,
    required this.promiseDate,
    required this.sellerPhotoPath,
    required this.lines,
  });

  double get grossWeight =>
      lines.fold(0, (total, line) => total + line.grossWeight);

  double get netWeight =>
      lines.fold(0, (total, line) => total + line.netWeight);

  double get fineWeight =>
      lines.fold(0, (total, line) => total + line.fineWeight);

  bool get hasPendingPayout => balanceDue > 0.005;

  bool get hasSellerPhoto => sellerPhotoPath?.trim().isNotEmpty ?? false;

  String get resolvedPaymentStatus {
    if (hasPendingPayout && totalPaid > 0.005) {
      return 'PARTIAL';
    }
    if (hasPendingPayout) {
      return 'PENDING';
    }
    final normalized = paymentStatus.trim();
    return normalized.isEmpty ? 'PAID' : normalized;
  }
}

class CustomerMetalPurchaseVoucherLine {
  final int id;
  final int lineNo;
  final String metalType;
  final String itemDescription;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purity;
  final double fineWeight;
  final double rate;
  final int quantity;
  final double lineAmount;

  const CustomerMetalPurchaseVoucherLine({
    required this.id,
    required this.lineNo,
    required this.metalType,
    required this.itemDescription,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purity,
    required this.fineWeight,
    required this.rate,
    required this.quantity,
    required this.lineAmount,
  });
}
