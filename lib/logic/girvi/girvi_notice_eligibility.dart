import '../../models/girvi/girvi_enums.dart';
import 'girvi_risk_policy.dart';

/// A notice can be considered once the agreed maturity date has passed and
/// the open pledge still has a payable balance, regardless of partial receipts.
class GirviNoticeEligibility {
  const GirviNoticeEligibility._();

  static bool hasMaturedBalance({
    required GirviStatus status,
    required DateTime maturityDate,
    required double principalDue,
    required double interestDue,
    required DateTime asOf,
  }) {
    if (status.isClosed ||
        status == GirviStatus.readyForDelivery ||
        !principalDue.isFinite ||
        !interestDue.isFinite) {
      return false;
    }

    final maturityDay =
        DateTime(maturityDate.year, maturityDate.month, maturityDate.day);
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    return today.isAfter(maturityDay) &&
        principalDue + interestDue > GirviRiskPolicy.moneyTolerance;
  }
}
