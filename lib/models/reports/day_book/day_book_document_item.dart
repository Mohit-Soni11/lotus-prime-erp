class DayBookDocumentItem {
  const DayBookDocumentItem({
    required this.metal,
    required this.name,
    required this.netWeightGrams,
    this.quantity = 1,
  });

  final String metal;
  final String name;
  final double netWeightGrams;
  final int quantity;
}
