import 'day_book_document_item.dart';

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
    this.partyName,
    this.mobile,
    this.items = const [],
    this.savedPaid,
    this.savedDue,
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
  final String? partyName;
  final String? mobile;
  final List<DayBookDocumentItem> items;

  /// Current saved invoice/voucher payment snapshot, separate from today's collection.
  final double? savedPaid;
  final double? savedDue;

  DayBookDocument withCollection(double value) => DayBookDocument(
        kind: kind,
        sourceId: sourceId,
        number: number,
        date: date,
        amount: amount,
        status: status,
        tax: tax,
        collection: value,
        outstanding: outstanding,
        customerId: customerId,
        sourceType: sourceType,
        originalSourceId: originalSourceId,
        relatedEntityId: relatedEntityId,
        supplierId: supplierId,
        partyName: partyName,
        mobile: mobile,
        items: items,
        savedPaid: savedPaid,
        savedDue: savedDue,
      );

  DayBookDocument withParty({String? name, String? phone}) => DayBookDocument(
        kind: kind,
        sourceId: sourceId,
        number: number,
        date: date,
        amount: amount,
        status: status,
        tax: tax,
        collection: collection,
        outstanding: outstanding,
        customerId: customerId,
        sourceType: sourceType,
        originalSourceId: originalSourceId,
        relatedEntityId: relatedEntityId,
        supplierId: supplierId,
        partyName: name ?? partyName,
        mobile: phone ?? mobile,
        items: items,
        savedPaid: savedPaid,
        savedDue: savedDue,
      );

  bool get isVoided => const {'VOID', 'VOIDED', 'CANCELLED'}
      .contains(status.trim().toUpperCase());
}
