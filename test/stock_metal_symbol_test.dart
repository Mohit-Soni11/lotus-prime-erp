import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/theme/stock/add_stock/stock_metal_symbol.dart';

void main() {
  testWidgets('stock marks identify gold and silver independently',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              StockMetalSymbol(
                metal: StockMetalSymbolType.gold,
                color: Colors.amber,
              ),
              StockMetalSymbol(
                metal: StockMetalSymbolType.silver,
                color: Colors.blueGrey,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Au'), findsOneWidget);
    expect(find.text('Ag'), findsOneWidget);
  });
}
