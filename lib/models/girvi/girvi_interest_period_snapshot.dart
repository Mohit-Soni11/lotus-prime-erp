import 'girvi_loan_model.dart';

/// A persisted, verified interest-period snapshot.
///
/// Notice and recovery documents must read these values instead of rebuilding
/// historical interest from the loan's current settings.
class GirviInterestPeriodSnapshot {
  final int id;
  final int girviId;
  final int sequence;
  final DateTime periodFrom;
  final DateTime periodTo;
  final String interestType;
  final double openingAmount;
  final double monthlyRatePercent;
  final double interestPerMonth;
  final int chargeableMonths;
  final double periodInterest;
  final double closingAmount;
  final bool finalized;
  final String source;

  const GirviInterestPeriodSnapshot({
    required this.id,
    required this.girviId,
    required this.sequence,
    required this.periodFrom,
    required this.periodTo,
    required this.interestType,
    required this.openingAmount,
    required this.monthlyRatePercent,
    required this.interestPerMonth,
    required this.chargeableMonths,
    required this.periodInterest,
    required this.closingAmount,
    required this.finalized,
    required this.source,
  });

  GirviInterestBreakdownLine get breakdownLine => GirviInterestBreakdownLine(
        cycleNumber: sequence,
        months: chargeableMonths,
        principalBase: openingAmount,
        monthlyRatePercent: monthlyRatePercent,
        interestAmount: periodInterest,
        capitalizedAfterLine: finalized,
      );
}
