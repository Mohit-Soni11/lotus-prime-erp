enum DayBookDocumentKind {
  regularInvoice('Regular Invoice'),
  gstInvoice('GST Invoice'),
  advanceReceipt('Advance Receipt'),
  girviTicket('Girvi Ticket'),
  purchaseVoucher('Purchase Voucher'),
  returnVoucher('Return Voucher');

  const DayBookDocumentKind(this.label);
  final String label;
}

class DayBookDocument {
  const DayBookDocument({
    required this.kind,
    required this.sourceId,
    required this.number,
    required this.date,
    required this.amount,
    required this.status,
    this.tax,
    this.collection,
    this.outstanding,
  });

  final DayBookDocumentKind kind;
  final String sourceId;
  final String number;
  final DateTime date;
  final double amount;
  final String status;
  final double? tax;
  final double? collection;
  final double? outstanding;

  bool get isVoided =>
      status.toUpperCase() == 'VOID' || status.toUpperCase() == 'VOIDED';
}
