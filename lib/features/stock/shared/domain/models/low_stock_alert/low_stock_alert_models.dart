class LowStockAlertSummary {
  final int watchedGroups;
  final int lowGroups;
  final int criticalGroups;
  final int stockoutGroups;
  final int availableUnits;
  final double availableNetWeight;
  final DateTime? lastCheckedAt;

  const LowStockAlertSummary({
    required this.watchedGroups,
    required this.lowGroups,
    required this.criticalGroups,
    required this.stockoutGroups,
    required this.availableUnits,
    required this.availableNetWeight,
    required this.lastCheckedAt,
  });

  factory LowStockAlertSummary.empty() {
    return const LowStockAlertSummary(
      watchedGroups: 0,
      lowGroups: 0,
      criticalGroups: 0,
      stockoutGroups: 0,
      availableUnits: 0,
      availableNetWeight: 0,
      lastCheckedAt: null,
    );
  }
}

class LowStockAlertRule {
  final int id;
  final String metalType;
  final String itemType;
  final int thresholdUnits;
  final double thresholdNetWeight;
  final int reorderTargetUnits;
  final String preferredSupplierName;
  final bool isActive;

  const LowStockAlertRule({
    required this.id,
    required this.metalType,
    required this.itemType,
    required this.thresholdUnits,
    required this.thresholdNetWeight,
    required this.reorderTargetUnits,
    required this.preferredSupplierName,
    required this.isActive,
  });

  String get scopeLabel {
    final item = itemType.trim();
    if (item.isEmpty || item.toLowerCase() == LowStockConstants.anyItemKey) {
      return '$metalType / Any Item';
    }
    return '$metalType / $item';
  }
}

class LowStockRiskCard {
  final String metalType;
  final String itemType;
  final int availableUnits;
  final double availableNetWeight;
  final int thresholdUnits;
  final double thresholdNetWeight;
  final int reorderTargetUnits;
  final String preferredSupplierName;
  final String riskLevel;

  const LowStockRiskCard({
    required this.metalType,
    required this.itemType,
    required this.availableUnits,
    required this.availableNetWeight,
    required this.thresholdUnits,
    required this.thresholdNetWeight,
    required this.reorderTargetUnits,
    required this.preferredSupplierName,
    required this.riskLevel,
  });

  String get title {
    final item = itemType.trim();
    if (item.isEmpty || item.toLowerCase() == LowStockConstants.anyItemKey) {
      return '$metalType Stock';
    }
    return '$metalType $itemType';
  }

  int get suggestedReorderUnits {
    final gap = reorderTargetUnits - availableUnits;
    return gap < 0 ? 0 : gap;
  }

  bool get requiresAction => riskLevel != LowStockRiskLevel.stable;
}

class LowStockStockCard {
  final String level;
  final String metalType;
  final String gradeLabel;
  final String itemType;
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final double totalNetWeight;
  final double availableNetWeight;
  final double soldNetWeight;
  final int thresholdUnits;
  final double thresholdNetWeight;
  final int reorderTargetUnits;
  final int suggestedReorderUnits;
  final double suggestedReorderNetWeight;
  final String riskLevel;

  const LowStockStockCard({
    required this.level,
    required this.metalType,
    required this.gradeLabel,
    required this.itemType,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.totalNetWeight,
    required this.availableNetWeight,
    required this.soldNetWeight,
    required this.thresholdUnits,
    required this.thresholdNetWeight,
    required this.reorderTargetUnits,
    required this.suggestedReorderUnits,
    required this.suggestedReorderNetWeight,
    required this.riskLevel,
  });

  String get title {
    switch (level) {
      case LowStockCardLevel.metal:
        return '$metalType Stock';
      case LowStockCardLevel.grade:
        return gradeLabel;
      case LowStockCardLevel.itemGroup:
        final item = itemType.trim();
        return item.isEmpty ||
                item.toLowerCase() == LowStockConstants.anyItemKey
            ? '$metalType Items'
            : '$item $metalType Stock';
      default:
        final item = itemType.trim();
        return item.isEmpty ||
                item.toLowerCase() == LowStockConstants.anyItemKey
            ? 'Any Item'
            : item;
    }
  }

  String get subtitle {
    switch (level) {
      case LowStockCardLevel.metal:
        return 'Open grades and low-stock groups';
      case LowStockCardLevel.grade:
        return '$metalType grade stock movement';
      case LowStockCardLevel.itemGroup:
        return 'Open purity and low-stock detail';
      default:
        return '$metalType / $gradeLabel';
    }
  }

  bool get requiresAction => riskLevel != LowStockRiskLevel.stable;
}

class LowStockAlertDashboard {
  final LowStockAlertSummary summary;
  final List<LowStockRiskCard> riskCards;
  final List<LowStockStockCard> metalCards;
  final List<LowStockStockCard> gradeCards;
  final List<LowStockStockCard> itemGroupCards;
  final List<LowStockStockCard> itemTypeCards;
  final List<LowStockAlertRule> rules;

  const LowStockAlertDashboard({
    required this.summary,
    required this.riskCards,
    required this.metalCards,
    required this.gradeCards,
    required this.itemGroupCards,
    required this.itemTypeCards,
    required this.rules,
  });

  factory LowStockAlertDashboard.empty() {
    return LowStockAlertDashboard(
      summary: LowStockAlertSummary.empty(),
      riskCards: const [],
      metalCards: const [],
      gradeCards: const [],
      itemGroupCards: const [],
      itemTypeCards: const [],
      rules: const [],
    );
  }
}

class LowStockCardLevel {
  LowStockCardLevel._();

  static const String metal = 'metal';
  static const String grade = 'grade';
  static const String itemGroup = 'itemGroup';
  static const String itemType = 'itemType';
}

class LowStockRiskLevel {
  LowStockRiskLevel._();

  static const String stable = 'stable';
  static const String low = 'low';
  static const String critical = 'critical';
  static const String stockout = 'stockout';
}

class LowStockConstants {
  LowStockConstants._();

  static const String anyItemKey = 'any';
}
