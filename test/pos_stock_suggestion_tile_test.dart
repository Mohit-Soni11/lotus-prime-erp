import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/stock_lookup/gold_stock_suggestion_tile.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/stock_lookup/pos_stock_suggestion_tile.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/stock_lookup/silver_stock_suggestion_tile.dart';

void main() {
  testWidgets('routes gold suggestions to the gold card implementation',
      (tester) async {
    await tester.pumpWidget(
      _tileHost(
        const PosStockLookupModel(
          stockItemId: 1,
          stockUnitId: 11,
          sku: 'PUR-GOLD-001',
          itemName: 'Casting Tops',
          description: '',
          huid: 'BXZ01A',
          purity: '18KT',
          metal: MetalType.gold,
          categoryLabel: 'Tops',
          companyName: 'Test Ornaments',
          grossWeight: 0.680,
          lessWeight: 0,
          netWeight: 0.680,
          unitCost: 45200,
          quantity: 1,
          availableQuantity: 1,
          quantityUnitLabel: 'pcs',
          status: 'Available',
        ),
      ),
    );

    expect(find.byType(GoldStockSuggestionTile), findsOneWidget);
    expect(find.byType(SilverStockSuggestionTile), findsNothing);
    expect(find.text('Casting Tops'), findsOneWidget);
    expect(find.text('Tops'), findsOneWidget);
    expect(find.text('Test Ornaments'), findsOneWidget);
    expect(find.textContaining('Cost'), findsNothing);
    expect(find.textContaining('45200'), findsNothing);
  });

  testWidgets('routes silver suggestions to the silver card implementation',
      (tester) async {
    await tester.pumpWidget(
      _tileHost(
        const PosStockLookupModel(
          stockItemId: 2,
          stockUnitId: 22,
          sku: 'PUR-SILVER-001',
          itemName: 'Silver Payal',
          description: '',
          huid: 'SV1234',
          purity: '925',
          metal: MetalType.silver,
          categoryLabel: 'Payal',
          companyName: 'Silver House',
          grossWeight: 12,
          lessWeight: 0,
          netWeight: 12,
          quantity: 2,
          availableQuantity: 1,
          quantityUnitLabel: 'pair',
          status: 'Available',
        ),
      ),
    );

    expect(find.byType(SilverStockSuggestionTile), findsOneWidget);
    expect(find.byType(GoldStockSuggestionTile), findsNothing);
    expect(find.text('Silver Payal'), findsOneWidget);
    expect(find.text('Payal'), findsOneWidget);
    expect(find.text('Silver House'), findsOneWidget);
  });

  testWidgets('keeps HUID column blank when stock has no HUID', (tester) async {
    await tester.pumpWidget(
      _tileHost(
        const PosStockLookupModel(
          stockItemId: 3,
          stockUnitId: 33,
          sku: 'PUR-SILVER-1784200000-001',
          itemName: 'Fancy Payal',
          description: '',
          huid: '',
          purity: '999',
          metal: MetalType.silver,
          categoryLabel: 'Payal',
          companyName: 'Sukh',
          grossWeight: 280,
          lessWeight: 0,
          netWeight: 280,
          quantity: 1,
          availableQuantity: 1,
          quantityUnitLabel: 'pcs',
          status: 'Available',
        ),
      ),
    );

    expect(find.byType(SilverStockSuggestionTile), findsOneWidget);
    expect(find.text('Fancy Payal'), findsOneWidget);
    expect(find.textContaining('PUR-SILVER'), findsNothing);
  });
}

Widget _tileHost(PosStockLookupModel item) {
  return MaterialApp(
    home: Scaffold(
      body: Material(
        child: SizedBox(
          width: 420,
          child: PosStockSuggestionTile(
            item: item,
            onTap: () {},
          ),
        ),
      ),
    ),
  );
}
