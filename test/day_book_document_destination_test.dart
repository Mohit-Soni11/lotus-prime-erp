import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_activity_event.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_document_destination.dart';

void main() {
  final date = DateTime(2026, 11, 4);
  DayBookDocument record(
    DayBookDocumentKind kind, {
    String sourceId = '9',
    int? customerId = 4,
    int? supplierId,
    String? sourceType,
    int? originalSourceId,
    int? relatedEntityId,
  }) =>
      DayBookDocument(
        kind: kind,
        sourceId: sourceId,
        number: 'DOC-9',
        date: date,
        amount: 100,
        status: 'POSTED',
        customerId: customerId,
        supplierId: supplierId,
        sourceType: sourceType,
        originalSourceId: originalSourceId,
        relatedEntityId: relatedEntityId,
      );

  test('each linked source opens the matching profile record', () {
    expect(dayBookDocumentDestination(record(DayBookDocumentKind.gstInvoice)),
        '/app/customer/profile/4?billId=9');
    expect(dayBookDocumentDestination(record(DayBookDocumentKind.girviTicket)),
        '/app/customer/profile/4?girviId=9');
    expect(
        dayBookDocumentDestination(
            record(DayBookDocumentKind.advanceReceipt, relatedEntityId: 7)),
        '/app/customer/profile/4?advanceId=7');
    expect(
        dayBookDocumentDestination(record(DayBookDocumentKind.returnVoucher,
            sourceType: 'SALES_INVOICE', originalSourceId: 3)),
        '/app/customer/profile/4?billId=3');
    expect(
        dayBookDocumentDestination(record(
            DayBookDocumentKind.advanceCancellationVoucher,
            sourceType: 'ADVANCE_BOOKING',
            originalSourceId: 7)),
        '/app/customer/profile/4?advanceId=7');
    expect(
        dayBookDocumentDestination(record(DayBookDocumentKind.purchaseVoucher,
            sourceType: 'CUSTOMER')),
        '/app/reports/purchase/voucher/9');
    expect(
        dayBookDocumentDestination(record(DayBookDocumentKind.purchaseVoucher,
            sourceType: 'SUPPLIER', supplierId: 6, customerId: null)),
        '/app/supplier/profile/6?voucherId=9');
    expect(
        dayBookActivityDestination(DayBookActivityEvent(
            kind: DayBookActivityKind.girviMelted,
            sourceId: 5,
            number: 'GRV-5',
            date: date,
            amount: 0,
            customerId: 4)),
        '/app/customer/profile/4?girviId=5');
    expect(
        dayBookActivityDestination(DayBookActivityEvent(
            kind: DayBookActivityKind.dueCollection,
            sourceId: 9,
            number: 'INV-9',
            date: date,
            amount: 300,
            customerId: 4)),
        '/app/customer/profile/4?billId=9');
  });

  test('posted receipt reference opens the related source when known', () {
    DayBookMoneyEntry receipt(String category, String reference) =>
        DayBookMoneyEntry(
          date: date,
          amount: 300,
          incoming: true,
          isCash: true,
          category: category,
          paymentMode: 'CASH',
          transactionId: 'RCPT-1',
          referenceId: reference,
        );
    final invoice = record(DayBookDocumentKind.regularInvoice);
    final due = DayBookActivityEvent(
      kind: DayBookActivityKind.dueCollection,
      sourceId: 9,
      number: 'INV-9',
      date: date,
      amount: 300,
      customerId: 4,
    );
    expect(
        dayBookReceiptDestination(
            receipt('SALE_PAYMENT', 'DOC-9#CASH'), [invoice], const []),
        '/app/customer/profile/4?billId=9');
    expect(
        dayBookReceiptDestination(
            receipt('DUE_COLLECTION', 'INV-9'), const [], [due]),
        '/app/customer/profile/4?billId=9');
    expect(
        dayBookReceiptDestination(
            receipt('DUE_COLLECTION', 'UNKNOWN'), const [], [due]),
        isNull);
  });
}
