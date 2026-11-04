enum DayBookActivityKind {
  girviRelease,
  girviInterest,
  girviMelted,
  dueCollection,
}

class DayBookActivityEvent {
  const DayBookActivityEvent({
    required this.kind,
    required this.sourceId,
    required this.number,
    required this.date,
    required this.amount,
    required this.customerId,
  });

  final DayBookActivityKind kind;
  final int sourceId;
  final String number;
  final DateTime date;
  final double amount;
  final int? customerId;
}
