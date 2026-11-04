import 'day_book_activity_event.dart';
import 'day_book_document.dart';
import 'day_book_expense_record.dart';
import 'day_book_models.dart';
import 'day_book_money_flow.dart';

/// Presentation-only sample records for reviewing the Day Book card design.
/// No repository or ledger reads this data.
class DayBookDemoPreview {
  const DayBookDemoPreview._();

  static DayBookSummary forDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    DayBookDocument document(
      DayBookDocumentKind kind,
      String number,
      double amount, {
      double? collection,
      double? tax,
      double? outstanding,
      String? sourceType,
    }) =>
        DayBookDocument(
          kind: kind,
          sourceId: 'preview-$number',
          number: number,
          date: day,
          amount: amount,
          status: 'PREVIEW',
          collection: collection,
          tax: tax,
          outstanding: outstanding,
          sourceType: sourceType,
        );

    DayBookActivityEvent event(
      DayBookActivityKind kind,
      String number,
      double amount,
    ) =>
        DayBookActivityEvent(
          kind: kind,
          sourceId: 0,
          number: number,
          date: day,
          amount: amount,
          customerId: null,
        );

    DayBookMoneyEntry receipt(String reference, double amount, String category,
            {String mode = 'CASH'}) =>
        DayBookMoneyEntry(
          date: day,
          amount: amount,
          incoming: true,
          isCash: mode == 'CASH',
          category: category,
          paymentMode: mode,
          transactionId: 'PREVIEW-$reference',
          referenceId: reference,
          referenceType: 'PREVIEW',
        );

    return DayBookSummary(
      date: day,
      moneyFlow: DayBookMoneyFlow(openingCash: 0, openingBank: 0, entries: [
        receipt('INV-025', 60000, 'SALE_PAYMENT'),
        receipt('INV-026', 70000, 'SALE_PAYMENT', mode: 'UPI'),
        receipt('INV-027', 50000, 'SALE_PAYMENT'),
        receipt('INV-028', 45000, 'SALE_PAYMENT'),
        receipt('INV-029', 50000, 'SALE_PAYMENT'),
        receipt('TAX-030', 75000, 'SALE_PAYMENT', mode: 'UPI'),
        receipt('TAX-031', 65000, 'SALE_PAYMENT', mode: 'CARD'),
        receipt('TAX-032', 45000, 'SALE_PAYMENT', mode: 'BANK'),
        receipt('ADV-041', 40000, 'ADVANCE_RECEIVED'),
        receipt('ADV-042', 20000, 'ADVANCE_RECEIVED', mode: 'UPI'),
        receipt('INV-011', 2500, 'DUE_COLLECTION'),
        receipt('TAX-016', 1000, 'DUE_COLLECTION'),
        receipt('GRV-108', 30000, 'GIRVI_RETURN'),
        receipt('GRV-108 · Interest', 1500, 'INTEREST_RECEIVED'),
      ]),
      documents: [
        document(DayBookDocumentKind.regularInvoice, 'INV-025', 60000,
            collection: 60000),
        document(DayBookDocumentKind.regularInvoice, 'INV-026', 70000,
            collection: 70000),
        document(DayBookDocumentKind.regularInvoice, 'INV-027', 50000,
            collection: 50000),
        document(DayBookDocumentKind.regularInvoice, 'INV-028', 45000,
            collection: 45000),
        document(DayBookDocumentKind.regularInvoice, 'INV-029', 50000,
            collection: 50000),
        document(DayBookDocumentKind.gstInvoice, 'TAX-030', 80000,
            collection: 75000, tax: 14400, outstanding: 5000),
        document(DayBookDocumentKind.gstInvoice, 'TAX-031', 70000,
            collection: 65000, tax: 12600, outstanding: 5000),
        document(DayBookDocumentKind.gstInvoice, 'TAX-032', 50000,
            collection: 45000, tax: 9000, outstanding: 5000),
        document(DayBookDocumentKind.girviTicket, 'GRV-112', 90000),
        document(DayBookDocumentKind.girviTicket, 'GRV-113', 60000),
        document(
            DayBookDocumentKind.advanceReceipt, 'ADV-041 / Receipt 1', 40000,
            collection: 40000),
        document(
            DayBookDocumentKind.advanceReceipt, 'ADV-042 / Receipt 1', 20000,
            collection: 20000),
        document(
            DayBookDocumentKind.advanceCancellationVoucher, 'CAN-008', 10000,
            outstanding: 10000),
        document(DayBookDocumentKind.returnVoucher, 'RET-014', 7000,
            outstanding: 0),
        document(DayBookDocumentKind.returnVoucher, 'RET-015', 5000,
            outstanding: 0),
        document(DayBookDocumentKind.purchaseVoucher, 'PUR-057', 75000,
            collection: 70000, outstanding: 5000, sourceType: 'CUSTOMER'),
        document(DayBookDocumentKind.purchaseVoucher, 'PUR-058', 65000,
            collection: 60000, outstanding: 5000, sourceType: 'CUSTOMER'),
        document(DayBookDocumentKind.purchaseVoucher, 'PUR-059', 60000,
            collection: 50000, outstanding: 10000, sourceType: 'CUSTOMER'),
      ],
      activityEvents: [
        event(DayBookActivityKind.girviRelease, 'GRV-108', 30000),
        event(DayBookActivityKind.girviInterest, 'GRV-108', 1500),
        event(DayBookActivityKind.girviMelted, 'GRV-105', 0),
        event(DayBookActivityKind.dueCollection, 'INV-011', 2500),
        event(DayBookActivityKind.dueCollection, 'TAX-016', 1000),
      ],
      expenseRecords: const [
        DayBookExpenseRecord(
          reference: 'EXP-101',
          category: 'Shop Rent',
          amount: 12000,
          paymentMode: 'BANK',
          description: 'Monthly shop rent',
        ),
        DayBookExpenseRecord(
          reference: 'EXP-102',
          category: 'Personal Expense',
          amount: 3000,
          paymentMode: 'CASH',
          description: 'Owner personal withdrawal',
        ),
        DayBookExpenseRecord(
          reference: 'EXP-103',
          category: 'Electricity / Utilities',
          amount: 2500,
          paymentMode: 'UPI',
        ),
      ],
    );
  }
}
