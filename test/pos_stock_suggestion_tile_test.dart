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
          quantity: 1,
          status: 'Available',
        ),
      ),
    );

    expect(find.byType(GoldStockSuggestionTile), findsOneWidget);
    expect(find.byType(SilverStockSuggestionTile), findsNothing);
    expect(find.text('Casting Tops'), findsOneWidget);
    expect(find.textContaining('Company: Test Ornaments'), findsOneWidget);
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
          status: 'Available',
        ),
      ),
    );

    expect(find.byType(SilverStockSuggestionTile), findsOneWidget);
    expect(find.byType(GoldStockSuggestionTile), findsNothing);
    expect(find.text('Silver Payal'), findsOneWidget);
    expect(find.textContaining('Company: Silver House'), findsOneWidget);
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
