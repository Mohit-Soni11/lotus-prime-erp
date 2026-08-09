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
  final double availablePurityPercentValue;
  final double availableWastagePercent;
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
    required this.availablePurityPercentValue,
    required this.availableWastagePercent,
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
    availablePurityPercentValue: 0,
    availableWastagePercent: 0,
    soldNetWeight: 0,
    soldFineWeight: 0,
  );

  double get marginPercent {
    if (saleValue == 0) return 0;
    return profit / saleValue * 100;
  }

  double get availableValuationPurityPercent {
    if (availablePurityPercentValue > 0 || availableWastagePercent > 0) {
      return availablePurityPercent + availableWastagePercent;
    }
    if (availableNetWeight == 0) return 0;
    return availableValuationFine / availableNetWeight * 100;
  }

  double get availablePurityPercent {
    if (availablePurityPercentValue > 0) return availablePurityPercentValue;
    if (availableNetWeight == 0) return 0;
    return availableActualFine / availableNetWeight * 100;
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
  final double availableValuationFineWeight;
  final double availablePurityPercentValue;
  final double availableWastagePercent;
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
    required this.availableValuationFineWeight,
    required this.availablePurityPercentValue,
    required this.availableWastagePercent,
    required this.soldNetWeight,
    required this.soldFineWeight,
  });

  double get marginPercent {
    if (saleValue == 0) return 0;
    return profit / saleValue * 100;
  }

  double get availableValuationPurityPercent {
    if (availablePurityPercentValue > 0 || availableWastagePercent > 0) {
      return availablePurityPercent + availableWastagePercent;
    }
    if (availableNetWeight == 0) return 0;
    return availableValuationFineWeight / availableNetWeight * 100;
  }

  double get availablePurityPercent {
    if (availablePurityPercentValue > 0) return availablePurityPercentValue;
    if (availableNetWeight == 0) return 0;
    return availableFineWeight / availableNetWeight * 100;
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
  final double purityPercentValue;
  final double wastagePercent;
  final double valuationFine;
  final double ratePerGram;
  final double makingAmount;
  final String makingChargeType;
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
    required this.purityPercentValue,
    required this.wastagePercent,
    required this.valuationFine,
    required this.ratePerGram,
    required this.makingAmount,
    this.makingChargeType = 'Amount',
    required this.unitCost,
  });

  String get identifier => huid.trim().isEmpty ? unitCode : huid;

  String get huidLabel => huid.trim().isEmpty ? 'Not linked' : huid;

  String get unitLabel {
    final count = quantity <= 0 ? 1 : quantity;
    return _valuationUnitLabel(
      count: count,
      quantityMode: quantityMode,
      itemName: '$itemType $itemName',
    );
  }

  double get valuationPurityPercent {
    if (purityPercentValue > 0 || wastagePercent > 0) {
      return purityPercent + wastagePercent;
    }
    if (netWeight == 0) return 0;
    return valuationFine / netWeight * 100;
  }

  double get purityPercent {
    if (purityPercentValue > 0) return purityPercentValue;
    if (netWeight == 0) return 0;
    return actualFine / netWeight * 100;
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
  final double availableQuantity;
  final double soldQuantity;
  final String quantityUnitLabel;
  final double totalGrossWeight;
  final double totalNetWeight;
  final double availableNetWeight;
  final double soldNetWeight;
  final double totalFineWeight;
  final double valuationFineWeight;
  final double availableValuationFineWeight;
  final double soldValuationFineWeight;
  final double purityPercentValue;
  final double wastagePercent;
  final double availableFineWeight;
  final double soldFineWeight;
  final double ratePerGram;
  final double makingAmount;
  final int rateVariantCount;
  final int makingVariantCount;
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
    this.availableQuantity = 0,
    this.soldQuantity = 0,
    this.quantityUnitLabel = 'pcs',
    required this.totalGrossWeight,
    required this.totalNetWeight,
    required this.availableNetWeight,
    required this.soldNetWeight,
    required this.totalFineWeight,
    required this.valuationFineWeight,
    this.availableValuationFineWeight = 0,
    this.soldValuationFineWeight = 0,
    required this.purityPercentValue,
    required this.wastagePercent,
    required this.availableFineWeight,
    required this.soldFineWeight,
    required this.ratePerGram,
    required this.makingAmount,
    this.rateVariantCount = 1,
    this.makingVariantCount = 1,
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

  String get availableQuantityLabel =>
      valuationDisplayQuantityText(availableQuantity, quantityUnitLabel);

  String get soldQuantityLabel =>
      valuationDisplayQuantityText(soldQuantity, quantityUnitLabel);

  double get valuationPurityPercent {
    if (purityPercentValue > 0 || wastagePercent > 0) {
      return purityPercent + wastagePercent;
    }
    if (totalNetWeight == 0) return 0;
    return valuationFineWeight / totalNetWeight * 100;
  }

  double get purityPercent {
    if (purityPercentValue > 0) return purityPercentValue;
    if (totalNetWeight == 0) return 0;
    return totalFineWeight / totalNetWeight * 100;
  }
}

class SoldValuationRow {
  final int billId;
  final int? customerId;
  final String billNo;
  final String customerName;
  final DateTime? billDate;
  final String batchCode;
  final String metalType;
  final String itemName;
  final String huid;
  final String unitCode;
  final int quantity;
  final String quantityMode;
  final double netWeight;
  final double saleValue;
  final double costBasis;
  final double profit;

  const SoldValuationRow({
    required this.billId,
    required this.customerId,
    required this.billNo,
    required this.customerName,
    required this.billDate,
    required this.batchCode,
    required this.metalType,
    required this.itemName,
    required this.huid,
    required this.unitCode,
    required this.quantity,
    required this.quantityMode,
    required this.netWeight,
    required this.saleValue,
    required this.costBasis,
    required this.profit,
  });

  String get customerLabel =>
      customerName.trim().isEmpty ? 'Walk-in Customer' : customerName;

  String get huidLabel => huid.trim().isEmpty ? 'Not linked' : huid;

  String get unitLabel {
    final count = quantity <= 0 ? 1 : quantity;
    return _valuationUnitLabel(
      count: count,
      quantityMode: quantityMode,
      itemName: itemName,
    );
  }

  double get marginPercent {
    if (saleValue == 0) return 0;
    return profit / saleValue * 100;
  }
}

String _valuationUnitLabel({
  required int count,
  required String quantityMode,
  required String itemName,
}) {
  final label = valuationUnitName(
    quantityMode: quantityMode,
    itemName: itemName,
    plural: count != 1,
  );
  return '$count $label';
}

String valuationDisplayQuantityText(double value, String unitLabel) {
  final rounded = value.roundToDouble();
  final quantity = (value - rounded).abs() < 0.001
      ? rounded.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  final unit = valuationQuantityUnitName(
    unitLabel,
    plural: (value - 1).abs() > 0.001,
  );
  return '$quantity $unit';
}

String valuationQuantityUnitName(String unitLabel, {required bool plural}) {
  final normalized = unitLabel.trim().toLowerCase();
  return switch (normalized) {
    'packet' => plural ? 'packets' : 'packet',
    'pair' => plural ? 'pairs' : 'pair',
    'set' => plural ? 'sets' : 'set',
    'lot' => plural ? 'lots' : 'lot',
    'mixed' => plural ? 'units' : 'unit',
    _ => plural ? 'pcs' : 'pc',
  };
}

String valuationUnitName({
  required String quantityMode,
  required String itemName,
  required bool plural,
}) {
  final mode = quantityMode.trim().toLowerCase();
  final normalizedItem = itemName.trim().toLowerCase();
  final inferredPair = _containsAny(normalizedItem, const [
        'jhumka',
        'jumka',
        'jhumki',
        'earring',
        'ear ring',
        'tops',
        'bali',
        'kundal',
        'payal',
        'anklet',
        'bichhiya',
        'bichiya',
        'bichia',
        'toe ring',
        'toe-ring',
        'kada pair',
      ]) &&
      !_containsAny(normalizedItem, const [
        'single',
        'repair piece',
        'one piece',
        '1 piece',
      ]);
  final inferredSet = _containsAny(normalizedItem, const [
    'necklace set',
    'bridal set',
    'jewellery set',
    'jewelry set',
    'chudi set',
    'bangle set',
    'haar set',
    'har set',
  ]);

  if (mode == 'pair' || mode == 'pairs' || inferredPair) {
    return plural ? 'pairs' : 'pair';
  }
  if (mode == 'set' || mode == 'sets' || inferredSet) {
    return plural ? 'sets' : 'set';
  }
  if (mode == 'pack' || mode == 'packs' || mode == 'packet') {
    return plural ? 'packets' : 'packet';
  }
  if (mode == 'lot' || mode == 'bulk') {
    return plural ? 'lots' : 'lot';
  }
  return plural ? 'pcs' : 'pc';
}

bool _containsAny(String value, List<String> keywords) {
  return keywords.any(value.contains);
}
