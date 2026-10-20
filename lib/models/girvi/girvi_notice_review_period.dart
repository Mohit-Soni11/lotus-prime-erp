/// The customer receives the full review period after confirmed delivery.
/// The approved deadline remains a floor for notices saved before delivery.
class GirviNoticeReviewPeriod {
  const GirviNoticeReviewPeriod._();

  static Duration duration({
    required DateTime approvedAt,
    required DateTime? approvedDeadline,
    required int fallbackDays,
  }) {
    final saved = approvedDeadline?.difference(approvedAt);
    if (saved != null && saved > Duration.zero) return saved;
    return Duration(days: fallbackDays > 0 ? fallbackDays : 7);
  }

  static DateTime? deadline({
    required DateTime approvedAt,
    required DateTime? approvedDeadline,
    required DateTime? deliveredAt,
    required int fallbackDays,
  }) {
    if (deliveredAt == null) return null;
    final fromDelivery = deliveredAt.add(duration(
      approvedAt: approvedAt,
      approvedDeadline: approvedDeadline,
      fallbackDays: fallbackDays,
    ));
    if (approvedDeadline != null && approvedDeadline.isAfter(fromDelivery)) {
      return approvedDeadline;
    }
    return fromDelivery;
  }
}
