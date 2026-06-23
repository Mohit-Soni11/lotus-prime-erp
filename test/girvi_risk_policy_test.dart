import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_risk_policy.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';

void main() {
  group('GirviRiskPolicy', () {
    test('marks one to two unpaid interest months as early risk', () {
      final result = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2026, 1),
        maturityDate: DateTime(2026, 12),
        lastInterestPaidDate: DateTime(2026, 5),
        principalDue: 12000,
        interestDue: 1200,
        now: DateTime(2026, 7),
      );

      expect(result.stage, GirviRiskStage.earlyRisk);
      expect(result.severity, GirviRiskSeverity.low);
      expect(result.unpaidInterestMonths, 2);
      expect(result.isRiskAccount, isTrue);
    });

    test('marks three to five unpaid interest months as watchlist', () {
      final result = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2026, 1),
        maturityDate: DateTime(2026, 12),
        lastInterestPaidDate: DateTime(2026, 2),
        principalDue: 12000,
        interestDue: 2400,
        now: DateTime(2026, 6),
      );

      expect(result.stage, GirviRiskStage.watchlist);
      expect(result.severity, GirviRiskSeverity.medium);
      expect(result.unpaidInterestMonths, 4);
    });

    test('marks maturity expiry or six unpaid months as high risk', () {
      final maturityExpired = GirviRiskPolicy.assess(
        status: GirviStatus.overdue,
        startDate: DateTime(2026, 1),
        maturityDate: DateTime(2026, 6),
        lastInterestPaidDate: DateTime(2026, 7),
        principalDue: 12000,
        interestDue: 0,
        now: DateTime(2026, 7),
      );

      final sixMonthsUnpaid = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2026, 1),
        maturityDate: DateTime(2026, 12),
        lastInterestPaidDate: DateTime(2026, 1),
        principalDue: 12000,
        interestDue: 3600,
        now: DateTime(2026, 7),
      );

      expect(maturityExpired.stage, GirviRiskStage.highRisk);
      expect(sixMonthsUnpaid.stage, GirviRiskStage.highRisk);
      expect(sixMonthsUnpaid.unpaidInterestMonths, 6);
    });

    test('marks compound-plus-six-month exposure as critical', () {
      final result = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2025, 1),
        maturityDate: DateTime(2027, 1),
        lastInterestPaidDate: DateTime(2025, 1),
        principalDue: 12000,
        interestDue: 12960,
        now: DateTime(2026, 7),
      );

      expect(result.stage, GirviRiskStage.critical);
      expect(result.severity, GirviRiskSeverity.critical);
      expect(result.unpaidInterestMonths, 18);
    });

    test('keeps incomplete release settlement separate from delivery cases',
        () {
      final partialSettlement = GirviRiskPolicy.assess(
        status: GirviStatus.partialRelease,
        startDate: DateTime(2026, 1),
        maturityDate: DateTime(2026, 12),
        lastInterestPaidDate: DateTime(2026, 5),
        principalDue: 1000,
        interestDue: 200,
        now: DateTime(2026, 7),
      );

      final readyForDelivery = GirviRiskPolicy.assess(
        status: GirviStatus.readyForDelivery,
        startDate: DateTime(2026, 1),
        maturityDate: DateTime(2026, 12),
        lastInterestPaidDate: DateTime(2026, 7),
        principalDue: 0,
        interestDue: 0,
        now: DateTime(2026, 7),
      );

      expect(partialSettlement.stage, GirviRiskStage.settlementPending);
      expect(partialSettlement.isRiskAccount, isTrue);
      expect(readyForDelivery.stage, GirviRiskStage.readyForDelivery);
      expect(readyForDelivery.isRiskAccount, isFalse);
    });
  });
}
