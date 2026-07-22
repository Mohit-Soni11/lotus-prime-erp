part of 'low_stock_alert_repository.dart';

class _AvailableStockGroup {
  final String metalType;
  final String itemType;
  final int units;
  final double netWeight;

  const _AvailableStockGroup({
    required this.metalType,
    required this.itemType,
    required this.units,
    required this.netWeight,
  });

  factory _AvailableStockGroup.empty(String metalType, String itemType) {
    return _AvailableStockGroup(
      metalType: metalType,
      itemType: itemType,
      units: 0,
      netWeight: 0,
    );
  }
}

class _StockLedgerGroup {
  final String metalType;
  final String gradeLabel;
  final String itemType;
  final String unitLabel;
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final int totalSets;
  final int availableSets;
  final int soldSets;
  final double totalNetWeight;
  final double availableNetWeight;
  final double soldNetWeight;

  const _StockLedgerGroup({
    required this.metalType,
    required this.gradeLabel,
    required this.itemType,
    required this.unitLabel,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.totalSets,
    required this.availableSets,
    required this.soldSets,
    required this.totalNetWeight,
    required this.availableNetWeight,
    required this.soldNetWeight,
  });
}

class _EffectiveLowStockRule {
  final String ruleMode;
  final int criticalUnits;
  final int thresholdUnits;
  final int targetUnits;
  final double criticalNetWeight;
  final double thresholdNetWeight;
  final double targetNetWeight;
  final int targetSets;
  final int targetPackets;
  final int reorderTargetUnits;

  const _EffectiveLowStockRule({
    required this.ruleMode,
    required this.criticalUnits,
    required this.thresholdUnits,
    required this.targetUnits,
    required this.criticalNetWeight,
    required this.thresholdNetWeight,
    required this.targetNetWeight,
    required this.targetSets,
    required this.targetPackets,
    required this.reorderTargetUnits,
  });

  factory _EffectiveLowStockRule.fromRule(LowStockAlertRule rule) {
    return _EffectiveLowStockRule(
      ruleMode: LowStockRuleMode.manual,
      criticalUnits: rule.criticalUnits,
      thresholdUnits: rule.thresholdUnits,
      targetUnits:
          rule.targetUnits > 0 ? rule.targetUnits : rule.reorderTargetUnits,
      criticalNetWeight: rule.criticalNetWeight,
      thresholdNetWeight: rule.thresholdNetWeight,
      targetNetWeight: rule.targetNetWeight,
      targetSets: rule.targetSets,
      targetPackets: rule.targetPackets,
      reorderTargetUnits:
          rule.targetUnits > 0 ? rule.targetUnits : rule.reorderTargetUnits,
    );
  }

  factory _EffectiveLowStockRule.auto(_StockLedgerGroup group) {
    final targetUnits = group.totalUnits;
    final yellowUnits = targetUnits <= 1 ? 0 : (targetUnits * 0.50).ceil();
    final redUnits = targetUnits <= 1 ? 0 : (targetUnits * 0.30).ceil();
    final targetWeight = group.totalNetWeight;
    return _EffectiveLowStockRule(
      ruleMode: LowStockRuleMode.auto,
      criticalUnits: redUnits,
      thresholdUnits: yellowUnits,
      targetUnits: targetUnits,
      criticalNetWeight: targetWeight * 0.30,
      thresholdNetWeight: targetWeight * 0.50,
      targetNetWeight: targetWeight,
      targetSets: group.totalSets,
      targetPackets: group.totalSets,
      reorderTargetUnits: targetUnits,
    );
  }
}
