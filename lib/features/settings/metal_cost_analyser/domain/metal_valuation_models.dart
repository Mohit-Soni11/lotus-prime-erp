enum MetalValuationFilter {
  all('ALL', 'All Metals'),
  gold('GOLD', 'Gold'),
  silver('SILVER', 'Silver'),
  platinum('PLATINUM', 'Platinum'),
  diamond('DIAMOND', 'Diamond');

  const MetalValuationFilter(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  bool get isAll => this == MetalValuationFilter.all;

  static MetalValuationFilter fromMetalType(String value) {
    final normalized = value.trim().toUpperCase();
    return MetalValuationFilter.values.firstWhere(
      (filter) => filter.databaseValue == normalized,
      orElse: () => MetalValuationFilter.all,
    );
  }
}

class MetalValuationSnapshot {
  final MetalValuationSummary summary;
  final List<MetalValuationBreakdown> breakdown;
  final List<AvailableValuationRow> availableStock;
  final List<SoldValuationRow> soldStock;

  const MetalValuationSnapshot({
    required this.summary,
    required this.breakdown,
    required this.availableStock,
    required this.soldStock,
  });

  static const empty = MetalValuationSnapshot(
    summary: MetalValuationSummary.empty,
    breakdown: [],
    availableStock: [],
    soldStock: [],
  );
}

class MetalValuationSummary {
  final int availableUnits;
  final int soldUnits;
  final double availableCost;
  final double soldCost;
  final double saleValue;
  final double profit;
  final double availableNetWeight;
  final double availableActualFine;
  final double availableValuationFine;
  final double soldNetWeight;
  final double soldFineWeight;

  const MetalValuationSummary({
    required this.availableUnits,
    required this.soldUnits,
    required this.availableCost,
    required this.soldCost,
    required this.saleValue,
    required this.profit,
    required this.availableNetWeight,
    required this.availableActualFine,
    required this.availableValuationFine,
    required this.soldNetWeight,
    required this.soldFineWeight,
  });

  static const empty = MetalValuationSummary(
    availableUnits: 0,
    soldUnits: 0,
    availableCost: 0,
    soldCost: 0,
    saleValue: 0,
    profit: 0,
    availableNetWeight: 0,
    availableActualFine: 0,
    availableValuationFine: 0,
    soldNetWeight: 0,
    soldFineWeight: 0,
  );

  double get marginPercent {
    if (saleValue == 0) return 0;
    return profit / saleValue * 100;
  }
}

class MetalValuationBreakdown {
  final String metalType;
  final int availableUnits;
  final int soldUnits;
  final double availableCost;
  final double soldCost;
  final double saleValue;
  final double profit;
  final double availableNetWeight;
  final double availableFineWeight;
  final double soldNetWeight;
  final double soldFineWeight;

  const MetalValuationBreakdown({
    required this.metalType,
    required this.availableUnits,
    required this.soldUnits,
    required this.availableCost,
    required this.soldCost,
    required this.saleValue,
    required this.profit,
    required this.availableNetWeight,
    required this.availableFineWeight,
    required this.soldNetWeight,
    required this.soldFineWeight,
  });

  double get marginPercent {
    if (saleValue == 0) return 0;
    return profit / saleValue * 100;
  }
}

class AvailableValuationRow {
  final String metalType;
  final String batchCode;
  final String itemType;
  final String itemName;
  final String companyName;
  final String huid;
  final String unitCode;
  final double grossWeight;
  final double netWeight;
  final double actualFine;
  final double valuationFine;
  final double unitCost;

  const AvailableValuationRow({
    required this.metalType,
    required this.batchCode,
    required this.itemType,
    required this.itemName,
    required this.companyName,
    required this.huid,
    required this.unitCode,
    required this.grossWeight,
    required this.netWeight,
    required this.actualFine,
    required this.valuationFine,
    required this.unitCost,
  });

  String get identifier => huid.trim().isEmpty ? unitCode : huid;
}

class SoldValuationRow {
  final String billNo;
  final DateTime? billDate;
  final String metalType;
  final String itemName;
  final String huid;
  final String unitCode;
  final double netWeight;
  final double saleValue;
  final double costBasis;
  final double profit;

  const SoldValuationRow({
    required this.billNo,
    required this.billDate,
    required this.metalType,
    required this.itemName,
    required this.huid,
    required this.unitCode,
    required this.netWeight,
    required this.saleValue,
    required this.costBasis,
    required this.profit,
  });

  String get identifier => huid.trim().isEmpty ? unitCode : huid;

  double get marginPercent {
    if (saleValue == 0) return 0;
    return profit / saleValue * 100;
  }
}
