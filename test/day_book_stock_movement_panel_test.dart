import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_stock_movement.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_stock_movement_panel.dart';

void main() {
  testWidgets('owned stock panel stays usable on a narrow workspace',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookStockMovementPanel(movements: [
            DayBookStockMovement(
              id: 1,
              occurredAt: DateTime(2026, 6, 25, 12),
              movementType: 'SALE',
              metal: 'Gold',
              itemName: 'Diamond Studded Gold Ring',
              sourceType: 'SALES_INVOICE',
              sourceId: 'INV-123456789',
              quantityDelta: -1,
              grossWeightDelta: -12,
              netWeightDelta: -10,
              fineWeightDelta: -9.16,
            ),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Owned Stock Movement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
