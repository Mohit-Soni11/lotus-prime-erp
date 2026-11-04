class DayBookExpenseRecord {
  const DayBookExpenseRecord({
    required this.reference,
    required this.category,
    required this.amount,
    required this.paymentMode,
    this.description,
    this.partyName,
  });

  final String reference;
  final String category;
  final double amount;
  final String paymentMode;
  final String? description;
  final String? partyName;
}
