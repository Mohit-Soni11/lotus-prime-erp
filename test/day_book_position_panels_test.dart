import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_customer_metal_sales.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_owned_stock_position.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_position_panels.dart';

void main() {
  testWidgets('unverified stock does not show invented metal weights',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookPositionPanels(
          summary: DayBookSummary(
            date: DateTime(2026, 6, 25),
            openingGoldGrams: 100,
            openingSilverGrams: 200,
          ),
        ),
      ),
    ));
    expect(find.text('Opening Position'), findsOneWidget);
    expect(find.text('Closing Position'), findsOneWidget);
    expect(find.text('100.000 g'), findsNothing);
    expect(find.text('Invoice weight unavailable'), findsNWidgets(2));
    expect(find.text('Net Cash Flow'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cash plus bank and calculated metal flow use source values',
      (tester) async {
    final summary = DayBookSummary(
      date: DateTime(2026, 6, 25),
      moneyFlow: DayBookMoneyFlow(
        openingCash: 400000,
        openingBank: 5000,
        entries: [
          DayBookMoneyEntry(
            date: DateTime(2026, 6, 25),
            amount: 12000,
            incoming: true,
            isCash: false,
            category: 'SALE_PAYMENT',
            paymentMode: 'UPI',
            transactionId: 'BANK-1',
          ),
        ],
      ),
      ownedStockPosition: const DayBookOwnedStockPosition(
        gold: DayBookOwnedMetalPosition(
          openingGrams: 1200,
          inwardGrams: 20,
          soldGrams: 100,
          otherOutGrams: 0,
          closingGrams: 1120,
          isConsistent: true,
        ),
        silver: DayBookOwnedMetalPosition(
          openingGrams: 200,
          inwardGrams: 0,
          soldGrams: 10,
          otherOutGrams: 0,
          closingGrams: 190,
          isConsistent: true,
        ),
      ),
      customerMetalSales: const DayBookCustomerMetalSales(
        goldGrams: 95,
        silverGrams: 12,
        goldInvoices: 2,
        silverInvoices: 1,
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SingleChildScrollView(
        child: DayBookPositionPanels(summary: summary),
      )),
    ));
    expect(find.text('₹4,05,000'), findsOneWidget);
    expect(find.text('₹4,17,000'), findsOneWidget);
    expect(find.text('1.200 kg'), findsOneWidget);
    expect(find.text('1.120 kg'), findsOneWidget);
    expect(find.text('Gold Sold Today'), findsOneWidget);
    expect(find.text('Silver Sold Today'), findsOneWidget);
    expect(find.text('95.000 g'), findsOneWidget);
    expect(find.text('12.000 g'), findsOneWidget);
    expect(find.text('2 invoices · Owned stock out 100.000 g'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'lib/logo/gold.jpeg'),
        findsWidgets);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'lib/logo/silver and platinum .jpeg'),
        findsWidgets);
    expect(find.text('Net Cash Flow'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero gold and existing silver stock stay visible',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookPositionPanels(
            summary: DayBookSummary(
              date: DateTime(2026, 11, 4),
              ownedStockPosition: const DayBookOwnedStockPosition(
                gold: DayBookOwnedMetalPosition(
                  openingGrams: 0,
                  inwardGrams: 0,
                  soldGrams: 0,
                  otherOutGrams: 0,
                  closingGrams: 0,
                  isConsistent: true,
                ),
                silver: DayBookOwnedMetalPosition(
                  openingGrams: 609.288,
                  inwardGrams: 0,
                  soldGrams: 0,
                  otherOutGrams: 0,
                  closingGrams: 609.288,
                  isConsistent: true,
                ),
              ),
              customerMetalSales: const DayBookCustomerMetalSales(),
            ),
          ),
        ),
      ),
    ));
    expect(find.text('0.000 g'), findsNWidgets(4));
    expect(find.text('609.288 g'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
