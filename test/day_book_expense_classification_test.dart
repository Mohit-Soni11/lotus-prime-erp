import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_expense_classification.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';

void main() {
  test('only operational payments count as expenses', () {
    final date = DateTime(2026, 11, 2);
    DayBookMoneyEntry entry(String category, double amount,
            {bool incoming = false, bool transfer = false}) =>
        DayBookMoneyEntry(
          date: date,
          amount: amount,
          incoming: incoming,
          isCash: false,
          category: category,
          paymentMode: 'UPI',
          transactionId: '$category-$amount',
          isInternalTransfer: transfer,
        );

    final flow = DayBookMoneyFlow(
      openingCash: 0,
      openingBank: 0,
      entries: [
        entry('SHOP_RENT', 100),
        entry('PURCHASE_PAYMENT', 200),
        entry('GIRVI_GIVEN', 300),
        entry('REFUND', 40),
        entry('OWNER_DRAWING', 50),
        entry('GST_PAYMENT', 35),
        entry('MISC_DEBIT', 15),
        entry('CASH_DEPOSIT', 60, transfer: true),
        entry('SALE', 70, incoming: true),
      ],
    );

    final totals = DayBookExpenseClassification.totals(flow);
    expect(totals[DayBookOutflowPurpose.operations], 100);
    expect(totals[DayBookOutflowPurpose.purchases], 200);
    expect(totals[DayBookOutflowPurpose.girvi], 300);
    expect(totals[DayBookOutflowPurpose.refunds], 40);
    expect(totals[DayBookOutflowPurpose.owner], 50);
    expect(totals[DayBookOutflowPurpose.taxRemittance], 35);
    expect(totals[DayBookOutflowPurpose.other], 15);
    expect(totals.values.fold<double>(0, (sum, value) => sum + value), 740);
  });
}
