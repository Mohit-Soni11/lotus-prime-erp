import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_expense_record.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_smart_summary.dart';

void main() {
  final date = DateTime(2026, 11, 4);

  DayBookDocument document(
    DayBookDocumentKind kind,
    String number,
    double amount, {
    double? collection,
    double? outstanding,
    double? tax,
    String? sourceType,
    String status = 'POSTED',
  }) =>
      DayBookDocument(
        kind: kind,
        sourceId: number,
        number: number,
        date: date,
        amount: amount,
        collection: collection,
        outstanding: outstanding,
        tax: tax,
        status: status,
        sourceType: sourceType,
      );

  DayBookSmartCard card(DayBookSmartSummary result, DayBookCardType type) =>
      result.cards.singleWhere((item) => item.type == type);

  test('all eight cards remain available when there is no activity', () {
    final result = DayBookSmartSummary.fromDay(DayBookSummary(date: date));
    expect(result.cards.map((row) => row.type), [
      DayBookCardType.sales,
      DayBookCardType.advanceReceived,
      DayBookCardType.receipts,
      DayBookCardType.dues,
      DayBookCardType.girviGiven,
      DayBookCardType.returnAndCancellation,
      DayBookCardType.customerMetalPurchase,
      DayBookCardType.expenses,
    ]);
    expect(result.cards.every((row) => row.amount == 0), isTrue);
  });

  test('sales detail separates regular and GST value, tax, collection and dues',
      () {
    final result = DayBookSmartSummary.fromDay(DayBookSummary(
      date: date,
      documents: [
        document(DayBookDocumentKind.regularInvoice, 'INV-25', 25000,
            collection: 15000, outstanding: 10000),
        document(DayBookDocumentKind.gstInvoice, 'TAX-30', 50000,
            collection: 30000, outstanding: 20000, tax: 2500),
      ],
    ));
    final sales = card(result, DayBookCardType.sales);
    expect(sales.amount, 75000);
    expect(sales.groups.map((group) => group.label),
        ['Regular invoices', 'GST invoices']);
    expect(sales.groups.first.collection, 15000);
    expect(sales.groups.last.tax, 2500);
    expect(card(result, DayBookCardType.dues).amount, 30000);
  });

  test('legacy invoice with unknown issue due is not reported as zero', () {
    final result = DayBookSmartSummary.fromDay(DayBookSummary(
      date: date,
      documents: [
        document(DayBookDocumentKind.regularInvoice, 'INV-OLD', 25000,
            collection: 25000),
      ],
    ));
    expect(card(result, DayBookCardType.dues).hasUnknownDue, isTrue);
  });

  test('Girvi release and advance cancellation do not reduce given or received',
      () {
    final result = DayBookSmartSummary.fromDay(DayBookSummary(
      date: date,
      documents: [
        document(DayBookDocumentKind.girviTicket, 'GRV-1', 20000),
        document(DayBookDocumentKind.advanceReceipt, 'ADV-1', 10000),
        document(DayBookDocumentKind.advanceCancellationVoucher, 'CAN-1', 4000),
        document(DayBookDocumentKind.returnVoucher, 'RET-1', 3000),
      ],
      moneyFlow: DayBookMoneyFlow(openingCash: 0, openingBank: 0, entries: [
        DayBookMoneyEntry(
          date: date,
          amount: 5000,
          incoming: true,
          isCash: true,
          category: 'GIRVI_RETURN',
          paymentMode: 'CASH',
          transactionId: 'GRV-OLD',
        ),
      ]),
    ));
    expect(card(result, DayBookCardType.girviGiven).amount, 20000);
    expect(card(result, DayBookCardType.advanceReceived).amount, 10000);
    expect(card(result, DayBookCardType.returnAndCancellation).amount, 7000);
    expect(card(result, DayBookCardType.receipts).amount, 5000);
    expect(card(result, DayBookCardType.sales).amount, 0);
  });

  test('only customer metal purchases appear and voided sources are excluded',
      () {
    final result = DayBookSmartSummary.fromDay(DayBookSummary(
      date: date,
      documents: [
        document(DayBookDocumentKind.purchaseVoucher, 'PUR-C', 18000,
            sourceType: 'CUSTOMER'),
        document(DayBookDocumentKind.purchaseVoucher, 'PUR-S', 90000,
            sourceType: 'SUPPLIER'),
        document(DayBookDocumentKind.purchaseVoucher, 'PUR-V', 3000,
            sourceType: 'CUSTOMER', status: 'VOID'),
        document(DayBookDocumentKind.purchaseVoucher, 'PUR-X', 4000,
            sourceType: 'CUSTOMER', status: 'CANCELLED'),
      ],
    ));
    expect(card(result, DayBookCardType.customerMetalPurchase).amount, 18000);
    expect(card(result, DayBookCardType.customerMetalPurchase).count, 1);
  });

  test('posted receipts ignore transfers; expense records remain independent',
      () {
    final result = DayBookSmartSummary.fromDay(DayBookSummary(
      date: date,
      moneyFlow: DayBookMoneyFlow(openingCash: 0, openingBank: 0, entries: [
        DayBookMoneyEntry(
          date: date,
          amount: 5000,
          incoming: true,
          isCash: true,
          category: 'DUE_COLLECTION',
          paymentMode: 'CASH',
          transactionId: 'RCPT-1',
        ),
        DayBookMoneyEntry(
          date: date,
          amount: 5000,
          incoming: true,
          isCash: false,
          category: 'TRANSFER_IN',
          paymentMode: 'BANK',
          transactionId: 'TRF-1',
          isInternalTransfer: true,
        ),
      ]),
      expenseRecords: const [
        DayBookExpenseRecord(
            reference: 'EXP-1',
            category: 'Shop Rent',
            amount: 2000,
            paymentMode: 'CASH'),
      ],
    ));
    expect(card(result, DayBookCardType.receipts).amount, 5000);
    expect(card(result, DayBookCardType.expenses).amount, 2000);
    expect(card(result, DayBookCardType.sales).amount, 0);
  });
}
