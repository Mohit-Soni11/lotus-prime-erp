import '../girvi/girvi_risk_policy.dart';
import '../../models/girvi/girvi_loan_model.dart';

/// A recent collection moves a still-open overdue account into follow-up.
/// The normal risk stage resumes if no further payment arrives next month.
class RiskPaymentMonitoring {
  const RiskPaymentMonitoring._();

  static const int monitoringWindowMonths = 1;

  static bool applies({
    required bool isMaturityOverdue,
    required double totalDue,
    required DateTime maturityDate,
    required DateTime? lastPaymentDate,
    required DateTime asOf,
  }) {
    final paymentDay = lastPaymentDate == null
        ? null
        : DateTime(
            lastPaymentDate.year, lastPaymentDate.month, lastPaymentDate.day);
    final maturityDay =
        DateTime(maturityDate.year, maturityDate.month, maturityDate.day);
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    if (!isMaturityOverdue ||
        totalDue <= GirviRiskPolicy.moneyTolerance ||
        paymentDay == null ||
        !paymentDay.isAfter(maturityDay) ||
        paymentDay.isAfter(today)) {
      return false;
    }
    return GirviLoanModel.chargeableMonthsBetween(paymentDay, today) <=
        monitoringWindowMonths;
  }
}
