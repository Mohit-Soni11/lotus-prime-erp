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

    test('keeps long unpaid exposure high risk before maturity', () {
      final result = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2025, 1),
        maturityDate: DateTime(2027, 1),
        lastInterestPaidDate: DateTime(2025, 1),
        principalDue: 12000,
        interestDue: 12960,
        now: DateTime(2026, 7),
      );

      expect(result.stage, GirviRiskStage.highRisk);
      expect(result.severity, GirviRiskSeverity.high);
      expect(result.unpaidInterestMonths, 18);
    });

    test('keeps old paid accounts in high risk before maturity', () {
      final result = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2025, 1),
        maturityDate: DateTime(2027, 1),
        lastInterestPaidDate: DateTime(2025, 8),
        principalDue: 12000,
        interestDue: 7200,
        hasCollectionHistory: true,
        now: DateTime(2026, 7),
      );

      expect(result.stage, GirviRiskStage.highRisk);
      expect(result.severity, GirviRiskSeverity.high);
      expect(result.isRiskAccount, isTrue);
    });

    test(
        'marks matured 12 month plus accounts with no term interest as critical',
        () {
      final result = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2025, 7),
        maturityDate: DateTime(2026, 7),
        lastInterestPaidDate: null,
        principalDue: 12000,
        interestDue: 7200,
        hasCollectionHistory: false,
        hasInterestPaidBeforeMaturity: false,
        now: DateTime(2026, 8),
      );

      expect(result.stage, GirviRiskStage.critical);
      expect(result.severity, GirviRiskSeverity.critical);
      expect(result.isRiskAccount, isTrue);
    });

    test(
        'keeps matured accounts critical when payment coverage is still above threshold',
        () {
      final result = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2025, 1),
        maturityDate: DateTime(2025, 7),
        lastInterestPaidDate: DateTime(2025, 2),
        principalDue: 12000,
        interestDue: 8500,
        hasCollectionHistory: true,
        hasInterestPaidBeforeMaturity: true,
        coveredInterestMonths: 1,
        now: DateTime(2026, 7),
      );

      expect(result.stage, GirviRiskStage.critical);
      expect(result.severity, GirviRiskSeverity.critical);
      expect(result.unpaidInterestMonths, 17);
      expect(result.isRiskAccount, isTrue);
    });

    test(
        'moves matured accounts to monitoring when payment brings unpaid months within threshold',
        () {
      final result = GirviRiskPolicy.assess(
        status: GirviStatus.active,
        startDate: DateTime(2025, 1),
        maturityDate: DateTime(2025, 7),
        lastInterestPaidDate: DateTime(2025, 6),
        principalDue: 12000,
        interestDue: 6000,
        hasCollectionHistory: true,
        hasInterestPaidBeforeMaturity: true,
        coveredInterestMonths: 6,
        now: DateTime(2026, 7),
      );

      expect(result.stage, GirviRiskStage.collectionMonitoring);
      expect(result.severity, GirviRiskSeverity.medium);
      expect(result.unpaidInterestMonths, 12);
      expect(result.isRiskAccount, isTrue);
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
