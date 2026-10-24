import 'girvi_customer_response_model.dart';

/// One recovery clock shared by the account screen and persistence boundary.
class GirviRecoveryEligibility {
  const GirviRecoveryEligibility._();

  static DateTime? availableAt({
    required DateTime? deliveredAt,
    required DateTime? noticeDeadline,
    GirviCustomerResponseKind? responseKind,
    DateTime? followUpDate,
  }) {
    if (deliveredAt == null) return null;
    if (responseKind == GirviCustomerResponseKind.recoveryRequest) {
      return deliveredAt;
    }
    if (noticeDeadline == null) return null;
    if (followUpDate != null) {
      // A selected calendar date remains protected through the end of that day.
      final afterFollowUpDay = DateTime(
        followUpDate.year,
        followUpDate.month,
        followUpDate.day + 1,
      );
      if (afterFollowUpDay.isAfter(noticeDeadline)) return afterFollowUpDay;
    }
    return noticeDeadline;
  }
}
