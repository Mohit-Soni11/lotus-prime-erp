enum ReturnReversalSourceDocumentType {
  salesInvoice('Sales Invoice'),
  advanceBooking('Advance Booking'),
  customerPurchase('Customer Purchase');

  final String label;

  const ReturnReversalSourceDocumentType(this.label);
}

class ReturnReversalSourceLineItem {
  final int lineNo;
  final String metalType;
  final String description;
  final String hsnCode;
  final String purity;
  final int quantity;
  final String quantityUnitCode;
  final double grossWeight;
  final double lessWeight;
  final bool lessWeightPerPiece;
  final double netWeight;
  final double fineWeight;
  final double rate;
  final String makingChargeType;
  final double makingChargeInput;
  final double makingAmount;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double invoiceValue;
  final double value;
  final String huidNumber;
  final String linkedStockSku;
  final String status;

  const ReturnReversalSourceLineItem({
    required this.lineNo,
    required this.metalType,
    required this.description,
    this.hsnCode = '',
    this.purity = '-',
    required this.quantity,
    this.quantityUnitCode = '',
    required this.grossWeight,
    this.lessWeight = 0,
    this.lessWeightPerPiece = false,
    required this.netWeight,
    this.fineWeight = 0,
    required this.rate,
    this.makingChargeType = 'PER_GRAM',
    this.makingChargeInput = 0,
    this.makingAmount = 0,
    this.discountAmount = 0,
    this.taxableAmount = 0,
    this.gstAmount = 0,
    this.invoiceValue = 0,
    required this.value,
    this.huidNumber = '',
    this.linkedStockSku = '',
    required this.status,
  });

  String get makingChargeSymbol {
    return switch (makingChargeType.trim().toUpperCase()) {
      'PERCENTAGE' => '%',
      'PER_KG' => '/kg',
      'PER_PIECE' => '/pc',
      _ => metalType.trim().toUpperCase().contains('DIAMOND') ? '/ct' : '/g',
    };
  }

  double get displayFineWeight => fineWeight > 0 ? fineWeight : netWeight;

  double get displayLineTotal => value;
}

class ReturnReversalSourceDocument {
  final int id;
  final ReturnReversalSourceDocumentType type;
  final String documentNo;
  final String customerName;
  final String mobile;
  final String address;
  final DateTime documentDate;
  final double grossValue;
  final double discountAmount;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double makingTotal;
  final double roundOffAmount;
  final double finalAmount;
  final double paidAmount;
  final double cashPaid;
  final double upiPaid;
  final double cardPaid;
  final double advancePaid;
  final double dueAmount;
  final double tradeInDeduction;
  final String paymentStatus;
  final String billingMode;
  final String gstPricingMode;
  final double netWeight;
  final List<ReturnReversalSourceLineItem> lineItems;

  const ReturnReversalSourceDocument({
    required this.id,
    required this.type,
    required this.documentNo,
    required this.customerName,
    required this.mobile,
    required this.address,
    required this.documentDate,
    required this.grossValue,
    this.discountAmount = 0,
    this.taxableAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.gstAmount = 0,
    this.makingTotal = 0,
    this.roundOffAmount = 0,
    double? finalAmount,
    required this.paidAmount,
    this.cashPaid = 0,
    this.upiPaid = 0,
    this.cardPaid = 0,
    this.advancePaid = 0,
    required this.dueAmount,
    this.tradeInDeduction = 0,
    this.paymentStatus = '',
    this.billingMode = '',
    this.gstPricingMode = '',
    required this.netWeight,
    required this.lineItems,
  }) : finalAmount = finalAmount ?? grossValue;

  int get itemCount => lineItems.length;

  bool get hasLineItems => lineItems.isNotEmpty;
}

class ReturnReversalLookupResult {
  final List<ReturnReversalSourceDocument> salesInvoices;
  final List<ReturnReversalSourceDocument> advanceBookings;
  final List<ReturnReversalSourceDocument> customerPurchases;

  const ReturnReversalLookupResult({
    required this.salesInvoices,
    required this.advanceBookings,
    required this.customerPurchases,
  });

  const ReturnReversalLookupResult.empty()
      : salesInvoices = const [],
        advanceBookings = const [],
        customerPurchases = const [];

  List<ReturnReversalSourceDocument> get allDocuments => [
        ...salesInvoices,
        ...advanceBookings,
        ...customerPurchases,
      ];

  bool get hasDocuments => allDocuments.isNotEmpty;
}
