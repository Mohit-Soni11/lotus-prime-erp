import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/girvi/girvi_interest_calculator.dart';

void main() {
  group('dated annual capitalization', () {
    final start = DateTime(2025, 1, 1);

    GirviInterestQuote quote(
      DateTime asOf, [
      List<GirviInterestAdjustment> adjustments = const [],
    ]) =>
        GirviInterestCalculator.quoteAt(
          principal: 100000,
          monthlyRatePercent: 1,
          startDate: start,
          asOf: asOf,
          adjustments: adjustments,
        );

    test('unpaid first-year interest capitalizes at the anniversary', () {
      final result = quote(DateTime(2026, 2, 1));
      expect(result.grossInterest, 13120);
      expect(result.interestOutstanding, 13120);
      expect(result.currentMonthlyInterest, 1120);
      expect(result.cycles.first.closingAmount, 112000);
      expect(result.cycles.last.principalBase, 112000);
    });

    test('interest paid on anniversary does not earn interest', () {
      final payments = [
        GirviInterestAdjustment(date: DateTime(2026, 1, 1), paid: 12000),
      ];
      final result = quote(DateTime(2026, 2, 1), payments);
      expect(result.grossInterest, 13000);
      expect(result.interestOutstanding, 1000);
      expect(result.currentMonthlyInterest, 1000);
      expect(result.cycles.first.closingAmount, 100000);
      expect(result.cycles.last.principalBase, 100000);
      expect(
        GirviInterestCalculator.coveredMonthsForTimeline(
          principal: 100000,
          monthlyRatePercent: 1,
          startDate: start,
          asOf: DateTime(2026, 1, 1),
          adjustments: payments,
        ),
        12,
      );
    });

    test('only unpaid half of first-year interest capitalizes', () {
      final result = quote(DateTime(2026, 2, 1), [
        GirviInterestAdjustment(date: DateTime(2026, 1, 1), paid: 6000),
      ]);
      expect(result.grossInterest, 13060);
      expect(result.interestOutstanding, 7060);
      expect(result.currentMonthlyInterest, 1060);
      expect(result.cycles.first.closingAmount, 106000);
    });

    test('late payment changes future charges without rewriting prior ones',
        () {
      final result = quote(DateTime(2026, 3, 1), [
        GirviInterestAdjustment(date: DateTime(2026, 1, 2), paid: 12000),
      ]);
      expect(result.grossInterest, 14120);
      expect(result.interestOutstanding, 2120);
      expect(result.cycles.last.interestAmount, 2120);
      expect(result.currentMonthlyInterest, 1000);
    });

    test('advance payment is carried forward; discount is not cash credit', () {
      final paid = quote(DateTime(2026, 2, 1), [
        GirviInterestAdjustment(date: DateTime(2025, 12, 1), paid: 13000),
      ]);
      final discounted = quote(DateTime(2026, 2, 1), [
        GirviInterestAdjustment(
          date: DateTime(2026, 1, 1),
          discount: 13000,
        ),
      ]);
      expect(paid.grossInterest, 13000);
      expect(paid.interestOutstanding, 0);
      expect(paid.advanceInterestCredit, 0);
      expect(discounted.interestOutstanding, 1000);
      expect(discounted.advanceInterestCredit, 0);
    });
  });

  test('chargeable months respect calendar anniversaries', () {
    expect(
      GirviInterestCalculator.chargeableMonthsBetween(
        DateTime(2025, 1, 31),
        DateTime(2025, 2, 28),
      ),
      1,
    );
    expect(
      GirviInterestCalculator.chargeableMonthsBetween(
        DateTime(2025, 1, 31),
        DateTime(2025, 3, 1),
      ),
      2,
    );
  });

  test('GRV-0019 monthly basis follows capitalized interest after payment', () {
    GirviInterestQuote quote(List<GirviInterestAdjustment> adjustments) =>
        GirviInterestCalculator.quoteAt(
          principal: 3000,
          monthlyRatePercent: 5,
          startDate: DateTime(2025, 5, 5),
          asOf: DateTime(2026, 10, 19),
          adjustments: adjustments,
        );

    final beforePayment = quote(const []);
    expect(beforePayment.interestType, GirviInterestCalculationType.compound);
    expect(beforePayment.currentMonthlyInterestType,
        GirviInterestCalculationType.compound);
    expect(beforePayment.currentInterestBase, 4800);
    expect(beforePayment.currentMonthlyInterest, 240);
    expect(beforePayment.lastChargedMonthlyInterestType,
        GirviInterestCalculationType.compound);
    expect(beforePayment.lastChargedMonthlyInterest, 240);

    final afterPayment = quote([
      GirviInterestAdjustment(date: DateTime(2026, 10, 19), paid: 2000),
    ]);
    expect(afterPayment.interestType, GirviInterestCalculationType.compound);
    expect(afterPayment.currentMonthlyInterestType,
        GirviInterestCalculationType.simple);
    expect(afterPayment.currentInterestBase, 3000);
    expect(afterPayment.currentMonthlyInterest, 150);
    expect(afterPayment.lastChargedMonthlyInterestType,
        GirviInterestCalculationType.compound);
    expect(afterPayment.lastChargedMonthlyInterest, 240);
    expect(afterPayment.grossInterest, 3240);
    expect(afterPayment.interestOutstanding, 1240);

    final nextAnniversary = GirviInterestCalculator.quoteAt(
      principal: 3000,
      monthlyRatePercent: 5,
      startDate: DateTime(2025, 5, 5),
      asOf: DateTime(2027, 5, 5),
      adjustments: [
        GirviInterestAdjustment(date: DateTime(2026, 10, 19), paid: 2000),
      ],
    );
    expect(nextAnniversary.currentMonthlyInterestType,
        GirviInterestCalculationType.compound);
    expect(nextAnniversary.currentInterestBase, 5140);
    expect(nextAnniversary.currentMonthlyInterest, 257);
    expect(nextAnniversary.lastChargedMonthlyInterestType,
        GirviInterestCalculationType.simple);
    expect(nextAnniversary.lastChargedMonthlyInterest, 150);

    final thirdYear = GirviInterestCalculator.quoteAt(
      principal: 3000,
      monthlyRatePercent: 5,
      startDate: DateTime(2025, 5, 5),
      asOf: DateTime(2027, 6, 5),
      adjustments: [
        GirviInterestAdjustment(date: DateTime(2026, 10, 19), paid: 2000),
      ],
    );
    expect(thirdYear.lastChargedMonthlyInterestType,
        GirviInterestCalculationType.compound);
    expect(thirdYear.lastChargedMonthlyInterest, 257);
  });
}
