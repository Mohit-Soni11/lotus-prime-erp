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

  double get displayInvoiceValue => invoiceValue > 0 ? invoiceValue : value;
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
  final double paidAmount;
  final double dueAmount;
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
    required this.paidAmount,
    required this.dueAmount,
    required this.netWeight,
    required this.lineItems,
  });

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
