enum DayBookDocumentKind {
  regularInvoice('Regular Invoice'),
  gstInvoice('GST Invoice'),
  advanceReceipt('Advance Receipt'),
  advanceCancellationVoucher('Advance Cancellation'),
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
    this.customerId,
    this.sourceType,
    this.originalSourceId,
    this.relatedEntityId,
    this.supplierId,
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
  final int? customerId;
  final String? sourceType;
  final int? originalSourceId;
  final int? relatedEntityId;
  final int? supplierId;

  bool get isVoided =>
      status.toUpperCase() == 'VOID' || status.toUpperCase() == 'VOIDED';
}
