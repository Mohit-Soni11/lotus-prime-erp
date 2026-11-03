class DayBookStockMovement {
  const DayBookStockMovement({
    required this.id,
    required this.occurredAt,
    required this.movementType,
    required this.metal,
    required this.itemName,
    this.puritySnapshot,
    required this.sourceType,
    required this.sourceId,
    this.sourceLineNo,
    required this.quantityDelta,
    required this.grossWeightDelta,
    required this.netWeightDelta,
    required this.fineWeightDelta,
    this.sourceNumber,
  });

  final int id;
  final DateTime occurredAt;
  final String movementType;
  final String metal;
  final String itemName;
  final String? puritySnapshot;
  bool get purityVerified =>
      puritySnapshot != null && puritySnapshot!.trim().isNotEmpty;
  final String sourceType;
  final String sourceId;
  final int? sourceLineNo;
  final String? sourceNumber;
  final int quantityDelta;
  final double grossWeightDelta;
  final double netWeightDelta;
  final double fineWeightDelta;

  bool get isInward =>
      netWeightDelta > 0 || (netWeightDelta == 0 && quantityDelta > 0);
  bool get isOutward =>
      netWeightDelta < 0 || (netWeightDelta == 0 && quantityDelta < 0);
}
