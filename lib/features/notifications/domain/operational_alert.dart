class OperationalAlert {
  final String key;
  final String category;
  final String title;
  final String description;
  final String routeId;
  final int priority;
  final int? billId;
  final int? customerId;
  final int? loanId;
  final String? location;
  final String? sourceRevision;

  const OperationalAlert({
    required this.key,
    required this.category,
    required this.title,
    required this.description,
    required this.routeId,
    required this.priority,
    this.billId,
    this.customerId,
    this.loanId,
    this.location,
    this.sourceRevision,
  });
}
