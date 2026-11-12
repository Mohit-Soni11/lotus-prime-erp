import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_stock_added_batch.dart';
import 'support/day_book_stock_added_preview.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_theme.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_stock_added_panel.dart';

void main() {
  final date = DateTime(2026, 11, 4);

  test('preview values reconcile without item-level records', () {
    final batches = DayBookStockAddedPreview.forDate(date);
    expect(batches, hasLength(4));
    expect(batches.fold<double>(0, (sum, batch) => sum + batch.purchaseValue),
        201817);
    for (final batch in batches) {
      expect(batch.netWeightGrams * batch.ratePerGram! + batch.makingTotal!,
          batch.purchaseValue);
    }
  });

  testWidgets('batch rows use existing gold and silver visuals',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: DayBookStyles.theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookStockAddedPanel(
            summary: DayBookSummary(
                date: date,
                stockAddedBatches: DayBookStockAddedPreview.forDate(date)),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Stock Added Today'), findsOneWidget);
    expect(find.text('4 Batches'), findsOneWidget);
    expect(find.text('₹2,01,817'), findsOneWidget);
    expect(find.text('STK-26-001473'), findsOneWidget);
    expect(find.text('Ring'), findsNothing);
    expect(find.text('Anklet Pair'), findsNothing);
    expect(find.byType(Image), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 900.0, 1100.0, 1225.0, 1600.0]) {
    testWidgets('batch rows do not overflow at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DayBookStockAddedPanel(
              summary: DayBookSummary(
                  date: date,
                  stockAddedBatches: DayBookStockAddedPreview.forDate(date)),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('posted batch opens its Inventory dossier route', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: DayBookStockAddedPanel(
            summary: DayBookSummary(date: date, stockAddedBatches: [
              DayBookStockAddedBatch(
                voucherId: 42,
                batchCode: 'GLD-42',
                metal: 'Gold',
                postedAt: date,
                pieces: 3,
                netWeightGrams: 30,
                ratePerGram: 6000,
                makingTotal: 5000,
                purchaseValue: 185000,
              ),
            ]),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockInventory,
        builder: (context, state) => Scaffold(
          body: Text('Opened ${state.uri.queryParameters['batch']} '
              '${state.uri.queryParameters['metal']}'),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GLD-42'));
    await tester.pumpAndSettle();
    expect(find.text('Opened GLD-42 Gold'), findsOneWidget);
  });
}
