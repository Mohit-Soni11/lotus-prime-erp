class StockSummaryOverview {
  final int openingUnits;
  final int inwardUnits;
  final int outwardUnits;
  final int restoredUnits;
  final int closingUnits;
  final double openingWeight;
  final double inwardWeight;
  final double outwardWeight;
  final double restoredWeight;
  final double closingWeight;
  final double closingFine;
  final int soldUnits;

  const StockSummaryOverview({
    required this.openingUnits,
    required this.inwardUnits,
    required this.outwardUnits,
    required this.restoredUnits,
    required this.closingUnits,
    required this.openingWeight,
    required this.inwardWeight,
    required this.outwardWeight,
    required this.restoredWeight,
    required this.closingWeight,
    required this.closingFine,
    required this.soldUnits,
  });

  factory StockSummaryOverview.empty() {
    return const StockSummaryOverview(
      openingUnits: 0,
      inwardUnits: 0,
      outwardUnits: 0,
      restoredUnits: 0,
      closingUnits: 0,
      openingWeight: 0,
      inwardWeight: 0,
      outwardWeight: 0,
      restoredWeight: 0,
      closingWeight: 0,
      closingFine: 0,
      soldUnits: 0,
    );
  }
}

class StockSummaryMetal {
  final String metal;
  final int availableUnits;
  final int soldUnits;
  final double grossWeight;
  final double netWeight;
  final double actualFine;

  const StockSummaryMetal({
    required this.metal,
    required this.availableUnits,
    required this.soldUnits,
    required this.grossWeight,
    required this.netWeight,
    required this.actualFine,
  });
}

class StockSummaryGrade {
  final String metal;
  final String gradeLabel;
  final int availableUnits;
  final int soldUnits;
  final double netWeight;
  final double actualFine;

  const StockSummaryGrade({
    required this.metal,
    required this.gradeLabel,
    required this.availableUnits,
    required this.soldUnits,
    required this.netWeight,
    required this.actualFine,
  });
}

class StockSummaryMovement {
  final String movementType;
  final String sourceNumber;
  final String metal;
  final String itemName;
  final int quantity;
  final double netWeight;
  final DateTime? occurredAt;

  const StockSummaryMovement({
    required this.movementType,
    required this.sourceNumber,
    required this.metal,
    required this.itemName,
    required this.quantity,
    required this.netWeight,
    required this.occurredAt,
  });

  bool get isInward => movementType == 'IN';
  bool get isSold => movementType == 'SALE';
  bool get isRestore => movementType == 'SALE_RESTORE';
}
