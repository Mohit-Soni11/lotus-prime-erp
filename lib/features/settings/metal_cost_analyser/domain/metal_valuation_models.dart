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
  final List<BatchValuationRow> batchSummaries;
  final List<AvailableValuationRow> availableStock;
  final List<SoldValuationRow> soldStock;

  const MetalValuationSnapshot({
    required this.summary,
    required this.breakdown,
    required this.batchSummaries,
    required this.availableStock,
    required this.soldStock,
  });

  static const empty = MetalValuationSnapshot(
    summary: MetalValuationSummary.empty,
    breakdown: [],
    batchSummaries: [],
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
  final int quantity;
  final String quantityMode;
  final double grossWeight;
  final double netWeight;
  final double actualFine;
  final double valuationFine;
  final double ratePerGram;
  final double makingAmount;
  final double unitCost;

  const AvailableValuationRow({
    required this.metalType,
    required this.batchCode,
    required this.itemType,
    required this.itemName,
    required this.companyName,
    required this.huid,
    required this.unitCode,
    required this.quantity,
    required this.quantityMode,
    required this.grossWeight,
    required this.netWeight,
    required this.actualFine,
    required this.valuationFine,
    required this.ratePerGram,
    required this.makingAmount,
    required this.unitCost,
  });

  String get identifier => huid.trim().isEmpty ? unitCode : huid;

  String get huidLabel => huid.trim().isEmpty ? 'Not linked' : huid;

  String get unitLabel {
    final count = quantity <= 0 ? 1 : quantity;
    final mode = quantityMode.trim().toUpperCase();
    final label = switch (mode) {
      'PAIR' || 'PAIRS' => count == 1 ? 'pair' : 'pairs',
      'PACK' ||
      'PACKS' ||
      'PACKET' ||
      'PACKETS' =>
        count == 1 ? 'packet' : 'packets',
      _ => count == 1 ? 'pc' : 'pcs',
    };
    return '$count $label';
  }
}

class BatchValuationRow {
  final String batchCode;
  final String metalType;
  final String supplierName;
  final DateTime? createdAt;
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final double totalGrossWeight;
  final double totalNetWeight;
  final double availableNetWeight;
  final double soldNetWeight;
  final double totalFineWeight;
  final double valuationFineWeight;
  final double availableFineWeight;
  final double soldFineWeight;
  final double ratePerGram;
  final double makingAmount;
  final double totalCost;
  final double availableCost;
  final double soldCost;
  final double saleValue;
  final double profit;

  const BatchValuationRow({
    required this.batchCode,
    required this.metalType,
    required this.supplierName,
    required this.createdAt,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.totalGrossWeight,
    required this.totalNetWeight,
    required this.availableNetWeight,
    required this.soldNetWeight,
    required this.totalFineWeight,
    required this.valuationFineWeight,
    required this.availableFineWeight,
    required this.soldFineWeight,
    required this.ratePerGram,
    required this.makingAmount,
    required this.totalCost,
    required this.availableCost,
    required this.soldCost,
    required this.saleValue,
    required this.profit,
  });

  double get marginPercent {
    if (saleValue == 0) return 0;
    return profit / saleValue * 100;
  }
}

class SoldValuationRow {
  final String billNo;
  final DateTime? billDate;
  final String batchCode;
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
    required this.batchCode,
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
