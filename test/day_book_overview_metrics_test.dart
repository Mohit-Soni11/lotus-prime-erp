import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_overview_metrics.dart';

void main() {
  test('overview separates invoice value, posted sales receipts and old dues',
      () {
    final date = DateTime(2026, 6, 25);
    DayBookMoneyEntry entry(String id, String category, double amount,
            {bool isCash = true, bool incoming = true}) =>
        DayBookMoneyEntry(
          date: date,
          amount: amount,
          incoming: incoming,
          isCash: isCash,
          category: category,
          paymentMode: isCash ? 'CASH' : 'UPI',
          transactionId: id,
        );
    final summary = DayBookSummary(
      date: date,
      openingCash: 500,
      moneyFlow: DayBookMoneyFlow(openingCash: 500, openingBank: 0, entries: [
        entry('sale', 'SALE', 200),
        entry('gst', 'SALE_PAYMENT', 300, isCash: false),
        entry('due-cash', 'DUE_COLLECTION', 80),
        entry('due-bank', 'DUE_COLLECTION', 20, isCash: false),
        entry('expense', 'SHOP_RENT', 50, incoming: false),
      ]),
      documents: [
        DayBookDocument(
          kind: DayBookDocumentKind.regularInvoice,
          sourceId: '1',
          number: 'INV-1',
          date: date,
          amount: 1000,
          collection: 200,
          status: 'ACTIVE',
        ),
        DayBookDocument(
          kind: DayBookDocumentKind.gstInvoice,
          sourceId: '2',
          number: 'TAX-2',
          date: date,
          amount: 590,
          tax: 90,
          collection: 300,
          status: 'ACTIVE',
        ),
        DayBookDocument(
          kind: DayBookDocumentKind.purchaseVoucher,
          sourceId: '3',
          number: 'PUR-3',
          date: date,
          amount: 400,
          collection: 100,
          status: 'SAVED',
        ),
      ],
    );

    final metrics = DayBookOverviewMetrics.fromSummary(summary);
    expect(metrics.totalSales, 1590);
    expect(metrics.salesCollection, 500);
    expect(metrics.gstInvoiceCollection, 300);
    expect(metrics.invoiceTax, 90);
    expect(metrics.dueCollection, 100);
    expect(metrics.closingCounterCash, 730);
    expect(metrics.regularInvoiceCount, 1);
    expect(metrics.taxInvoiceCount, 1);
  });
}
