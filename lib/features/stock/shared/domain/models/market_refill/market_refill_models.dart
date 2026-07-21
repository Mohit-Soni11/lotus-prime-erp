class MarketRefillReport {
  final MarketRefillDateRange range;
  final MarketRefillSummary summary;
  final List<MarketRefillMetalSummary> metals;
  final List<MarketRefillItemRow> rows;

  const MarketRefillReport({
    required this.range,
    required this.summary,
    required this.metals,
    required this.rows,
  });

  factory MarketRefillReport.empty(MarketRefillDateRange range) {
    return MarketRefillReport(
      range: range,
      summary: MarketRefillSummary.empty(),
      metals: const [],
      rows: const [],
    );
  }
}

class MarketRefillDateRange {
  final DateTime start;
  final DateTime end;
  final String label;

  const MarketRefillDateRange({
    required this.start,
    required this.end,
    required this.label,
  });
}

class MarketRefillSummary {
  final int soldQuantity;
  final int availableQuantity;
  final int refillQuantity;
  final int itemGroups;
  final int metalGroups;
  final double soldNetWeight;
  final double availableNetWeight;

  const MarketRefillSummary({
    required this.soldQuantity,
    required this.availableQuantity,
    required this.refillQuantity,
    required this.itemGroups,
    required this.metalGroups,
    required this.soldNetWeight,
    required this.availableNetWeight,
  });

  factory MarketRefillSummary.empty() {
    return const MarketRefillSummary(
      soldQuantity: 0,
      availableQuantity: 0,
      refillQuantity: 0,
      itemGroups: 0,
      metalGroups: 0,
      soldNetWeight: 0,
      availableNetWeight: 0,
    );
  }
}

class MarketRefillMetalSummary {
  final String metal;
  final int soldQuantity;
  final int availableQuantity;
  final int refillQuantity;
  final int itemGroups;
  final double soldNetWeight;
  final double availableNetWeight;

  const MarketRefillMetalSummary({
    required this.metal,
    required this.soldQuantity,
    required this.availableQuantity,
    required this.refillQuantity,
    required this.itemGroups,
    required this.soldNetWeight,
    required this.availableNetWeight,
  });
}

class MarketRefillItemRow {
  final String metal;
  final String gradeLabel;
  final String companyName;
  final String itemType;
  final String unitLabel;
  final int soldQuantity;
  final int availableQuantity;
  final int refillQuantity;
  final double soldNetWeight;
  final double availableNetWeight;
  final int billCount;
  final String latestInvoice;
  final DateTime? lastSoldAt;
  final List<String> companyNames;
  final List<String> itemNames;

  const MarketRefillItemRow({
    required this.metal,
    required this.gradeLabel,
    required this.companyName,
    required this.itemType,
    required this.unitLabel,
    required this.soldQuantity,
    required this.availableQuantity,
    required this.refillQuantity,
    required this.soldNetWeight,
    required this.availableNetWeight,
    required this.billCount,
    required this.latestInvoice,
    required this.lastSoldAt,
    required this.companyNames,
    required this.itemNames,
  });

  String get title {
    final item = itemType.trim();
    if (item.isEmpty) return '$metal Stock';
    return item;
  }

  String get statusLabel {
    if (availableQuantity <= 0) return 'Refill Now';
    if (availableQuantity <= refillQuantity) return 'Plan Refill';
    return 'Watch';
  }

  String get companyLabel {
    if (companyName.trim().isNotEmpty) return companyName.trim();
    if (companyNames.isEmpty) return 'Company not tagged';
    if (companyNames.length == 1) return companyNames.first;
    return '${companyNames.length} companies';
  }

  String get itemNameLabel {
    if (itemNames.isEmpty) return 'Item names not tagged';
    if (itemNames.length == 1) return itemNames.first;
    return '${itemNames.length} item names';
  }
}
