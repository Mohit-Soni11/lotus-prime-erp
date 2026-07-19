import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/inventory/inventory_stats_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/inventory/metal_hub/inventory_metal_summary_grid.dart';

void main() {
  testWidgets('inventory ledger shows only metals with available stock',
      (tester) async {
    StockCategory? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: InventoryMetalSummaryGrid(
              stats: _stats(goldCount: 3, silverCount: 12),
              selectedMetal: null,
              onMetalSelected: (metal) => selected = metal,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Gold Inventory Ledger'), findsOneWidget);
    expect(find.text('Silver Inventory Ledger'), findsOneWidget);
    expect(find.text('Diamond Inventory Ledger'), findsNothing);
    expect(find.text('Platinum Inventory Ledger'), findsNothing);

    await tester.tap(find.text('Silver Inventory Ledger'));
    expect(selected, StockCategory.silver);
  });

  testWidgets('inventory ledger shows an empty state when no metal has stock',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: InventoryMetalSummaryGrid(
              stats: InventoryStats.empty(),
              selectedMetal: null,
              onMetalSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Gold Inventory Ledger'), findsNothing);
    expect(find.text('Silver Inventory Ledger'), findsNothing);
    expect(
      find.text('Inventory ledger cards will appear once stock is available.'),
      findsOneWidget,
    );
  });
}

InventoryStats _stats({
  int goldCount = 0,
  int silverCount = 0,
  int diamondCount = 0,
  int platinumCount = 0,
}) {
  return InventoryStats(
    openingCount: goldCount + silverCount + diamondCount + platinumCount,
    openingWeight: 0,
    openingValue: 0,
    closingCount: goldCount + silverCount + diamondCount + platinumCount,
    closingWeight: 0,
    closingValue: 0,
    todayAdded: 0,
    todaySold: 0,
    goldCount: goldCount,
    goldWeight: goldCount * 10,
    goldValue: 0,
    silverCount: silverCount,
    silverWeight: silverCount * 12,
    silverValue: 0,
    diamondCount: diamondCount,
    diamondValue: 0,
    platinumCount: platinumCount,
    platinumWeight: platinumCount * 8,
  );
}
