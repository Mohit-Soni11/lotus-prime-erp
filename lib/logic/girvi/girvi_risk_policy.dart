// =============================================================================
// FILE        : girvi_risk_policy.dart
// MODULE      : Girvi / Risk & Collections
// LAYER       : Domain Policy
// DESCRIPTION : Single source of truth for Girvi collection risk stages.
// =============================================================================

import 'dart:math' as math;

import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';

enum GirviRiskStage {
  controlled,
  earlyRisk,
  watchlist,
  highRisk,
  critical,
  settlementPending,
  readyForDelivery,
}

enum GirviRiskSeverity {
  none,
  low,
  medium,
  high,
  critical,
}

class GirviRiskAssessment {
  final GirviRiskStage stage;
  final GirviRiskSeverity severity;
  final bool isRiskAccount;
  final bool isInterestOverdue;
  final bool isMaturityOverdue;
  final int unpaidInterestMonths;
  final int maturityOverdueDays;
  final int maturityOverdueMonths;
  final int riskAgeDays;
  final String statusLabel;
  final String stageLabel;
  final String nextActionLabel;

  const GirviRiskAssessment({
    required this.stage,
    required this.severity,
    required this.isRiskAccount,
    required this.isInterestOverdue,
    required this.isMaturityOverdue,
    required this.unpaidInterestMonths,
    required this.maturityOverdueDays,
    required this.maturityOverdueMonths,
    required this.riskAgeDays,
    required this.statusLabel,
    required this.stageLabel,
    required this.nextActionLabel,
  });
}

class GirviRiskPolicy {
  GirviRiskPolicy._();

  static const double moneyTolerance = 0.01;
  static const int earlyRiskStartMonths = 1;
  static const int watchlistStartMonths = 3;
  static const int highRiskStartMonths = 6;
  static const int criticalUnpaidStartMonths = 18;
  static const int criticalMaturityOverdueMonths = 6;

  static GirviRiskAssessment assess({
    required GirviStatus status,
    required DateTime startDate,
    required DateTime maturityDate,
    required DateTime? lastInterestPaidDate,
    required double principalDue,
    required double interestDue,
    required DateTime now,
  }) {
    final totalDue = principalDue + interestDue;
    final maturityOverdueDays = math.max(
      0,
      _dateOnly(now).difference(_dateOnly(maturityDate)).inDays,
    );
    final maturityOverdueMonths = maturityOverdueDays <= 0
        ? 0
        : GirviLoanModel.chargeableMonthsBetween(maturityDate, now);
    final interestStart = lastInterestPaidDate ?? startDate;
    final unpaidInterestMonths = interestDue > moneyTolerance
        ? GirviLoanModel.chargeableMonthsBetween(interestStart, now)
        : 0;
    final interestOverdueDays = unpaidInterestMonths > 0
        ? math.max(
            0, _dateOnly(now).difference(_dateOnly(interestStart)).inDays)
        : 0;
    final riskAgeDays = math.max(interestOverdueDays, maturityOverdueDays);
    final isInterestOverdue = unpaidInterestMonths >= earlyRiskStartMonths;
    final isMaturityOverdue =
        maturityOverdueDays > 0 || status == GirviStatus.overdue;

    if (status.isClosed) {
      return _result(
        stage: GirviRiskStage.controlled,
        severity: GirviRiskSeverity.none,
        isRiskAccount: false,
        isInterestOverdue: false,
        isMaturityOverdue: false,
        unpaidInterestMonths: 0,
        maturityOverdueDays: 0,
        maturityOverdueMonths: 0,
        riskAgeDays: 0,
      );
    }

    if (status == GirviStatus.readyForDelivery) {
      return _result(
        stage: GirviRiskStage.readyForDelivery,
        severity: GirviRiskSeverity.none,
        isRiskAccount: false,
        isInterestOverdue: false,
        isMaturityOverdue: isMaturityOverdue,
        unpaidInterestMonths: 0,
        maturityOverdueDays: maturityOverdueDays,
        maturityOverdueMonths: maturityOverdueMonths,
        riskAgeDays: maturityOverdueDays,
      );
    }

    if (totalDue <= moneyTolerance) {
      return _result(
        stage: GirviRiskStage.readyForDelivery,
        severity: GirviRiskSeverity.none,
        isRiskAccount: false,
        isInterestOverdue: false,
        isMaturityOverdue: isMaturityOverdue,
        unpaidInterestMonths: 0,
        maturityOverdueDays: maturityOverdueDays,
        maturityOverdueMonths: maturityOverdueMonths,
        riskAgeDays: maturityOverdueDays,
      );
    }

    if (status == GirviStatus.partialRelease) {
      return _result(
        stage: GirviRiskStage.settlementPending,
        severity: GirviRiskSeverity.low,
        isRiskAccount: true,
        isInterestOverdue: isInterestOverdue,
        isMaturityOverdue: isMaturityOverdue,
        unpaidInterestMonths: unpaidInterestMonths,
        maturityOverdueDays: maturityOverdueDays,
        maturityOverdueMonths: maturityOverdueMonths,
        riskAgeDays: riskAgeDays,
      );
    }

    if (unpaidInterestMonths >= criticalUnpaidStartMonths ||
        maturityOverdueMonths >= criticalMaturityOverdueMonths) {
      return _result(
        stage: GirviRiskStage.critical,
        severity: GirviRiskSeverity.critical,
        isRiskAccount: true,
        isInterestOverdue: isInterestOverdue,
        isMaturityOverdue: isMaturityOverdue,
        unpaidInterestMonths: unpaidInterestMonths,
        maturityOverdueDays: maturityOverdueDays,
        maturityOverdueMonths: maturityOverdueMonths,
        riskAgeDays: riskAgeDays,
      );
    }

    if (isMaturityOverdue || unpaidInterestMonths >= highRiskStartMonths) {
      return _result(
        stage: GirviRiskStage.highRisk,
        severity: GirviRiskSeverity.high,
        isRiskAccount: true,
        isInterestOverdue: isInterestOverdue,
        isMaturityOverdue: isMaturityOverdue,
        unpaidInterestMonths: unpaidInterestMonths,
        maturityOverdueDays: maturityOverdueDays,
        maturityOverdueMonths: maturityOverdueMonths,
        riskAgeDays: riskAgeDays,
      );
    }

    if (unpaidInterestMonths >= watchlistStartMonths) {
      return _result(
        stage: GirviRiskStage.watchlist,
        severity: GirviRiskSeverity.medium,
        isRiskAccount: true,
        isInterestOverdue: true,
        isMaturityOverdue: false,
        unpaidInterestMonths: unpaidInterestMonths,
        maturityOverdueDays: maturityOverdueDays,
        maturityOverdueMonths: maturityOverdueMonths,
        riskAgeDays: riskAgeDays,
      );
    }

    if (unpaidInterestMonths >= earlyRiskStartMonths) {
      return _result(
        stage: GirviRiskStage.earlyRisk,
        severity: GirviRiskSeverity.low,
        isRiskAccount: true,
        isInterestOverdue: true,
        isMaturityOverdue: false,
        unpaidInterestMonths: unpaidInterestMonths,
        maturityOverdueDays: maturityOverdueDays,
        maturityOverdueMonths: maturityOverdueMonths,
        riskAgeDays: riskAgeDays,
      );
    }

    return _result(
      stage: GirviRiskStage.controlled,
      severity: GirviRiskSeverity.none,
      isRiskAccount: false,
      isInterestOverdue: false,
      isMaturityOverdue: false,
      unpaidInterestMonths: 0,
      maturityOverdueDays: 0,
      maturityOverdueMonths: 0,
      riskAgeDays: 0,
    );
  }

  static GirviRiskAssessment _result({
    required GirviRiskStage stage,
    required GirviRiskSeverity severity,
    required bool isRiskAccount,
    required bool isInterestOverdue,
    required bool isMaturityOverdue,
    required int unpaidInterestMonths,
    required int maturityOverdueDays,
    required int maturityOverdueMonths,
    required int riskAgeDays,
  }) {
    return GirviRiskAssessment(
      stage: stage,
      severity: severity,
      isRiskAccount: isRiskAccount,
      isInterestOverdue: isInterestOverdue,
      isMaturityOverdue: isMaturityOverdue,
      unpaidInterestMonths: unpaidInterestMonths,
      maturityOverdueDays: maturityOverdueDays,
      maturityOverdueMonths: maturityOverdueMonths,
      riskAgeDays: riskAgeDays,
      statusLabel: _statusLabel(stage, isMaturityOverdue, isInterestOverdue),
      stageLabel: _stageLabel(stage),
      nextActionLabel: _nextAction(stage),
    );
  }

  static String _statusLabel(
    GirviRiskStage stage,
    bool isMaturityOverdue,
    bool isInterestOverdue,
  ) {
    switch (stage) {
      case GirviRiskStage.settlementPending:
        return 'Settlement Pending';
      case GirviRiskStage.readyForDelivery:
        return 'Ready for Delivery';
      case GirviRiskStage.controlled:
        return 'Controlled';
      default:
        if (isMaturityOverdue) return 'Maturity Overdue';
        if (isInterestOverdue) return 'Interest Overdue';
        return 'Active';
    }
  }

  static String _stageLabel(GirviRiskStage stage) {
    switch (stage) {
      case GirviRiskStage.critical:
        return 'Critical';
      case GirviRiskStage.highRisk:
        return 'High Risk';
      case GirviRiskStage.watchlist:
        return 'Watchlist';
      case GirviRiskStage.earlyRisk:
        return 'Early Risk';
      case GirviRiskStage.settlementPending:
        return 'Settlement Pending';
      case GirviRiskStage.readyForDelivery:
        return 'Ready for Delivery';
      case GirviRiskStage.controlled:
        return 'Controlled';
    }
  }

  static String _nextAction(GirviRiskStage stage) {
    switch (stage) {
      case GirviRiskStage.critical:
        return 'Review for notice or auction';
      case GirviRiskStage.highRisk:
        return 'Call customer and secure payment';
      case GirviRiskStage.watchlist:
        return 'Schedule collection follow-up';
      case GirviRiskStage.earlyRisk:
        return 'Send payment reminder';
      case GirviRiskStage.settlementPending:
        return 'Complete remaining settlement';
      case GirviRiskStage.readyForDelivery:
        return 'Move to delivery workflow';
      case GirviRiskStage.controlled:
        return 'No collection action required';
    }
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
