import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_export_service.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_owned_stock_position.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_customer_metal_sales.dart';

void main() {
  test('CSV and PDF include posted money position and transaction detail',
      () async {
    final date = DateTime(2026, 6, 25, 14);
    final summary = DayBookSummary(
      date: date,
      moneyFlow: DayBookMoneyFlow(
        openingCash: 100,
        openingBank: 1000,
        entries: [
          DayBookMoneyEntry(
            date: date,
            amount: 500,
            incoming: true,
            isCash: false,
            category: 'SALE_PAYMENT',
            paymentMode: 'UPI',
            transactionId: 'B-123',
            accountName: 'Current Account',
            referenceId: '=1+1',
          ),
        ],
      ),
    );

    final csv = DayBookExportService.buildCsv(summary);
    expect(csv, contains('"Money Position","Money In","500.00"'));
    expect(csv, contains('"Money In by Mode","UPI","500.00"'));
    expect(csv, contains('"Transaction B-123","Reference","\'=1+1"'));

    final pdf = await DayBookExportService.buildPdf(summary);
    expect(pdf.length, greaterThan(1000));
  });

  test('PDF transaction table spans multiple pages', () async {
    final date = DateTime(2026, 6, 25, 14);
    final summary = DayBookSummary(
      date: date,
      moneyFlow: DayBookMoneyFlow(
        openingCash: 0,
        openingBank: 0,
        entries: [
          for (var index = 0; index < 80; index++)
            DayBookMoneyEntry(
              date: date,
              amount: 100,
              incoming: true,
              isCash: index.isEven,
              category: 'SALE',
              paymentMode: index.isEven ? 'CASH' : 'UPI',
              transactionId: 'TXN-$index',
            ),
        ],
      ),
    );

    expect((await DayBookExportService.buildPdf(summary)).length,
        greaterThan(1000));
  });

  test('CSV position uses cash plus bank and calculated metal movements', () {
    final summary = DayBookSummary(
      date: DateTime(2026, 11, 4),
      openingGoldGrams: 100,
      openingSilverGrams: 200,
      moneyFlow:
          DayBookMoneyFlow(openingCash: 100, openingBank: 200, entries: []),
      ownedStockPosition: const DayBookOwnedStockPosition(
        gold: DayBookOwnedMetalPosition(
          openingGrams: 100,
          inwardGrams: 5,
          soldGrams: 10,
          otherOutGrams: 0,
          closingGrams: 95,
          isConsistent: true,
        ),
        silver: DayBookOwnedMetalPosition(
          openingGrams: 200,
          inwardGrams: 0,
          soldGrams: 0,
          otherOutGrams: 0,
          closingGrams: 200,
          isConsistent: true,
        ),
      ),
      customerMetalSales: const DayBookCustomerMetalSales(goldGrams: 12),
    );

    final csv = DayBookExportService.buildCsv(summary);
    expect(csv, contains('"Opening Position","Balance","300.00"'));
    expect(csv, contains('"Closing Position","Balance","300.00"'));
    expect(csv, contains('"Sales","Gold Sold to Customers (g)","12.000"'));
    expect(
        csv, contains('"Metal Movement","Gold Owned Stock Out (g)","10.000"'));
    expect(csv, contains('"Closing Position","Gold (g)","95.000"'));
  });
}
