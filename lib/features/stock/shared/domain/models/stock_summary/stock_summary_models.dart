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
  final double soldWeight;
  final double totalWeight;
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
    required this.soldWeight,
    required this.totalWeight,
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
      soldWeight: 0,
      totalWeight: 0,
      closingFine: 0,
      soldUnits: 0,
    );
  }
}

class StockSummaryMetal {
  final String metal;
  final int openingUnits;
  final int inwardUnits;
  final int outwardUnits;
  final int restoredUnits;
  final int closingUnits;
  final int availableUnits;
  final int soldUnits;
  final double openingWeight;
  final double inwardWeight;
  final double outwardWeight;
  final double restoredWeight;
  final double closingWeight;
  final double grossWeight;
  final double netWeight;
  final double soldWeight;
  final double totalWeight;
  final double actualFine;

  const StockSummaryMetal({
    required this.metal,
    required this.openingUnits,
    required this.inwardUnits,
    required this.outwardUnits,
    required this.restoredUnits,
    required this.closingUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.openingWeight,
    required this.inwardWeight,
    required this.outwardWeight,
    required this.restoredWeight,
    required this.closingWeight,
    required this.grossWeight,
    required this.netWeight,
    required this.soldWeight,
    required this.totalWeight,
    required this.actualFine,
  });
}

class StockSummaryGrade {
  final String metal;
  final String gradeLabel;
  final int openingUnits;
  final int inwardUnits;
  final int outwardUnits;
  final int restoredUnits;
  final int closingUnits;
  final int availableUnits;
  final int soldUnits;
  final double openingWeight;
  final double inwardWeight;
  final double outwardWeight;
  final double restoredWeight;
  final double closingWeight;
  final double netWeight;
  final double soldWeight;
  final double totalWeight;
  final double actualFine;

  const StockSummaryGrade({
    required this.metal,
    required this.gradeLabel,
    required this.openingUnits,
    required this.inwardUnits,
    required this.outwardUnits,
    required this.restoredUnits,
    required this.closingUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.openingWeight,
    required this.inwardWeight,
    required this.outwardWeight,
    required this.restoredWeight,
    required this.closingWeight,
    required this.netWeight,
    required this.soldWeight,
    required this.totalWeight,
    required this.actualFine,
  });
}

class StockSummaryItem {
  final String metal;
  final String gradeLabel;
  final String itemName;
  final String itemType;
  final String segment;
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final int companyCount;
  final int purityGroupCount;
  final int totalSets;
  final int availableSets;
  final double grossWeight;
  final double availableWeight;
  final double soldWeight;
  final double totalWeight;
  final double actualFine;

  const StockSummaryItem({
    required this.metal,
    required this.gradeLabel,
    required this.itemName,
    required this.itemType,
    required this.segment,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.companyCount,
    required this.purityGroupCount,
    required this.totalSets,
    required this.availableSets,
    required this.grossWeight,
    required this.availableWeight,
    required this.soldWeight,
    required this.totalWeight,
    required this.actualFine,
  });

  String get stockTitle => '${itemName.trim()} $metal Stock'.trim();

  String get stockStatus {
    if (availablePieces <= 0 && soldPieces > 0) return 'Sold Out';
    if (soldPieces > 0) return 'Partially Sold';
    return 'Ready Stock';
  }
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
