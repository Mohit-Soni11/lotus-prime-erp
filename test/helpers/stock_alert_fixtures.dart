import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';

LowStockStockCard stockAlertCard(
        {String metal = 'Gold',
        String item = 'Ring',
        String grade = '18KT (75%)',
        int available = 0,
        String unit = 'pcs'}) =>
    LowStockStockCard(
      level: LowStockCardLevel.itemType,
      metalType: metal,
      gradeLabel: grade,
      itemType: item,
      unitLabel: unit,
      totalUnits: 10,
      availableUnits: available,
      soldUnits: 10 - available,
      totalSets: 0,
      availableSets: 0,
      soldSets: 0,
      totalNetWeight: 50,
      availableNetWeight: available * 5.0,
      soldNetWeight: (10 - available) * 5.0,
      ruleMode: LowStockRuleMode.auto,
      criticalUnits: 1,
      thresholdUnits: 3,
      targetUnits: 10,
      criticalNetWeight: 5,
      thresholdNetWeight: 15,
      targetNetWeight: 50,
      targetSets: 0,
      targetPackets: 0,
      reorderTargetUnits: 10,
      suggestedReorderUnits: 10 - available,
      suggestedReorderNetWeight: (10 - available) * 5.0,
      riskLevel: available == 0
          ? LowStockRiskLevel.stockout
          : available == 1
              ? LowStockRiskLevel.critical
              : available <= 3
                  ? LowStockRiskLevel.low
                  : LowStockRiskLevel.stable,
    );
