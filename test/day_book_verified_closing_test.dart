import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_balance_verification.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_verified_closing.dart';

void main() {
  final day = DateTime(2026, 11, 11);

  DayBookBalanceVerification opening({
    required double expectedCash,
    required double actualCash,
    required double expectedBank,
    required double actualBank,
  }) =>
      DayBookBalanceVerification(
        date: day,
        verifiedAt: day,
        expectedCash: expectedCash,
        actualCash: actualCash,
        cashVariance: actualCash - expectedCash,
        expectedBank: expectedBank,
        actualBank: actualBank,
        bankVariance: actualBank - expectedBank,
      );

  DayBookMoneyEntry cash(double amount, bool incoming, String type) =>
      DayBookMoneyEntry(
        date: day,
        amount: amount,
        incoming: incoming,
        isCash: true,
        category: type == 'DAY_BOOK_BALANCE' ? 'MISC_EXPENSE' : 'SALE',
        paymentMode: 'CASH',
        transactionId: '$type-$amount',
        referenceType: type,
      );

  test('saved opening plus posted activity derives cash closing', () {
    final position = DayBookVerifiedClosing(
      opening: opening(
        expectedCash: 100,
        actualCash: 100,
        expectedBank: 50,
        actualBank: 50,
      ),
      money: DayBookMoneyFlow(
        openingCash: 100,
        openingBank: 50,
        entries: [cash(40, true, 'SALE')],
      ),
    );
    expect(position.closingCash, 140);
    expect(position.closingBank, 50);
    expect(position.matchesLedger, isTrue);
  });

  test('opening shortage posting is not deducted twice', () {
    final position = DayBookVerifiedClosing(
      opening: opening(
        expectedCash: 100,
        actualCash: 90,
        expectedBank: 50,
        actualBank: 50,
      ),
      money: DayBookMoneyFlow(
        openingCash: 100,
        openingBank: 50,
        entries: [
          cash(10, false, 'DAY_BOOK_BALANCE'),
          cash(40, true, 'SALE'),
        ],
      ),
    );
    expect(position.closingCash, 130);
    expect(position.matchesLedger, isTrue);
  });

  test('unposted verified bank excess blocks the closing bridge', () {
    final position = DayBookVerifiedClosing(
      opening: opening(
        expectedCash: 100,
        actualCash: 100,
        expectedBank: 50,
        actualBank: 60,
      ),
      money: DayBookMoneyFlow(
        openingCash: 100,
        openingBank: 50,
        entries: const [],
      ),
    );
    expect(position.closingBank, 60);
    expect(position.matchesLedger, isFalse);
  });
}
