import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_stock_movement.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_metal_position_panel.dart';

void main() {
  testWidgets('unverified metal balance does not present invented weights',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookMetalPositionPanel(
          summary: DayBookSummary(
            date: DateTime(2026, 6, 25),
            openingGoldGrams: 100,
            openingSilverGrams: 200,
          ),
        ),
      ),
    ));
    expect(find.text('Metal Position'), findsOneWidget);
    expect(find.text('Unverified'), findsOneWidget);
    expect(find.text('100.000 g'), findsNothing);
    expect(find.text('Opening Cash'), findsNothing);
    expect(find.text('Closing Cash'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verified metal balance shows separate opening and closing',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookMetalPositionPanel(
          summary: DayBookSummary(
            date: DateTime(2026, 6, 25),
            metalPositionVerified: true,
            openingGoldGrams: 100,
            openingSilverGrams: 200,
            stockMovements: [
              DayBookStockMovement(
                id: 1,
                occurredAt: DateTime(2026, 6, 25),
                movementType: 'IN',
                metal: 'Gold',
                itemName: 'Ring',
                sourceType: 'PURCHASE',
                sourceId: 'PUR-1',
                quantityDelta: 1,
                grossWeightDelta: 12,
                netWeightDelta: 10,
                fineWeightDelta: 9.16,
              ),
            ],
          ),
        ),
      ),
    ));
    expect(find.text('Unverified'), findsNothing);
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Silver'), findsOneWidget);
    expect(find.text('Opening'), findsNWidgets(2));
    expect(find.text('Closing'), findsNWidgets(2));
    expect(find.text('100.000 g'), findsOneWidget);
    expect(find.text('110.000 g'), findsOneWidget);
    expect(find.text('200.000 g'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
