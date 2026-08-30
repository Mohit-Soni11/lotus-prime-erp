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
  final int quantity;
  final double grossWeight;
  final double netWeight;
  final double rate;
  final double makingAmount;
  final double value;
  final String huidNumber;
  final String status;

  const ReturnReversalSourceLineItem({
    required this.lineNo,
    required this.metalType,
    required this.description,
    required this.quantity,
    required this.grossWeight,
    required this.netWeight,
    required this.rate,
    this.makingAmount = 0,
    required this.value,
    this.huidNumber = '',
    required this.status,
  });
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
