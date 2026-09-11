import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/sales_report/sales_report_models.dart';
import 'package:lotus_erp/theme/reports/sales_report/sales_report_theme.dart';
import 'package:lotus_erp/ui/report/sales_report/summary/sales_report_metal_cards.dart';

void main() {
  testWidgets('metal cards show readable dynamic period labels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: Scaffold(
          body: SalesReportMetalCards(
            metals: const [
              SalesReportMetalSummary(
                metalType: 'other',
                invoiceCount: 3,
                pieces: 7,
                netWeight: 25.5,
                salesAmount: 125000,
              ),
            ],
            selectedMetal: 'ALL',
            periodLabel: 'October 2026',
            onMetalSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Other Sales'), findsOneWidget);
    expect(
      find.textContaining('October 2026'),
      findsOneWidget,
    );
    expect(find.text('Sales Value'), findsOneWidget);
    expect(find.text('Net Weight Sold'), findsOneWidget);

    final salesValueLabel = tester.widget<Text>(find.text('Sales Value'));
    expect(salesValueLabel.style?.color, SalesReportColors.textPrimary);
    expect(salesValueLabel.style?.fontSize, 13.5);
    expect(salesValueLabel.style?.fontWeight, FontWeight.w900);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metal detail panel uses polished metric naming', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: Scaffold(
          body: SalesReportMetalDetailPanel(
            metal: const SalesReportMetalSummary(
              metalType: 'other',
              invoiceCount: 4,
              pieces: 9,
              netWeight: 30,
              salesAmount: 180000,
            ),
            periodLabel: 'November 2026',
            recordedGstAmount: 5400,
            projectedGstAmount: 2700,
            onBackToCards: () {},
          ),
        ),
      ),
    );

    expect(find.text('Other Sales Ledger'), findsOneWidget);
    expect(find.textContaining('November 2026'), findsOneWidget);
    expect(find.text('Bills With Other'), findsOneWidget);
    expect(find.text('Total Bills'), findsNothing);
    expect(find.text('Total Qty'), findsOneWidget);
    expect(find.text('GST Collected'), findsOneWidget);
    expect(find.text('Normal GST Estimate'), findsOneWidget);

    final billsWithMetalLabel =
        tester.widget<Text>(find.text('Bills With Other'));
    expect(billsWithMetalLabel.style?.color, SalesReportColors.textPrimary);
    expect(billsWithMetalLabel.style?.fontSize, 13.5);
    expect(billsWithMetalLabel.style?.fontWeight, FontWeight.w900);
    expect(tester.takeException(), isNull);
  });
}
