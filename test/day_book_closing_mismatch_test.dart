import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_closing_mismatch.dart';

void main() {
  final date = DateTime(2026, 11, 11);

  test('cash and bank shortages create separate dated expense drafts', () {
    const mismatch = DayBookClosingMismatch(
      expectedCash: 1000,
      countedCash: 900,
      expectedBank: 500,
      countedBank: 470,
    );
    final drafts = mismatch.expenseDrafts(date);
    expect(drafts, hasLength(2));
    expect(drafts[0].amount, 100);
    expect(drafts[0].paymentMode, PaymentMode.cash);
    expect(drafts[0].date, date);
    expect(drafts[1].amount, 30);
    expect(drafts[1].paymentMode, PaymentMode.bank);
    expect(drafts[1].date, date);
  });

  test('cash-bank offset is a transfer warning, not an expense', () {
    const mismatch = DayBookClosingMismatch(
      expectedCash: 1000,
      countedCash: 900,
      expectedBank: 500,
      countedBank: 600,
    );
    expect(mismatch.hasOppositeMovements, isTrue);
    expect(mismatch.expenseDrafts(date), isEmpty);
  });

  test('excess and incomplete counts do not create expense drafts', () {
    const excess = DayBookClosingMismatch(
      expectedCash: 1000,
      countedCash: 1010,
      expectedBank: 500,
      countedBank: 500,
    );
    const pending = DayBookClosingMismatch(
      expectedCash: 1000,
      countedCash: null,
      expectedBank: 500,
      countedBank: 500,
    );
    expect(excess.expenseDrafts(date), isEmpty);
    expect(pending.expenseDrafts(date), isEmpty);
  });

  test('a completed cash or bank count exposes its own shortage action', () {
    const cashOnly = DayBookClosingMismatch(
      expectedCash: 1000,
      countedCash: 900,
      expectedBank: 500,
      countedBank: null,
    );
    const bankOnly = DayBookClosingMismatch(
      expectedCash: 1000,
      countedCash: null,
      expectedBank: 500,
      countedBank: 470,
    );

    expect(cashOnly.expenseDrafts(date), hasLength(1));
    expect(cashOnly.expenseDrafts(date).single.paymentMode, PaymentMode.cash);
    expect(bankOnly.expenseDrafts(date), hasLength(1));
    expect(bankOnly.expenseDrafts(date).single.paymentMode, PaymentMode.bank);
  });
}
