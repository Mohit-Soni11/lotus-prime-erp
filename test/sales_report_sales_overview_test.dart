import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/sales_report/sales_report_models.dart';
import 'package:lotus_erp/theme/reports/sales_report/sales_report_theme.dart';
import 'package:lotus_erp/ui/report/sales_report/summary/sales_report_sales_overview.dart';

void main() {
  testWidgets('sales overview shows smart cards for active sales metrics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: SalesReportSalesOverview(
              periodLabel: 'September 2026',
              summary: SalesReportGstLiabilitySummary(
                invoiceCount: 6,
                gstInvoiceCount: 5,
                nonGstInvoiceCount: 1,
                gstTaxableAmount: 125000,
                gstFinalAmount: 128750,
                recordedGstAmount: 3750,
                nonGstSalesAmount: 12768,
                dueAmount: 9000,
                projectedGstRatePercent: 3,
                projectedGstAmount: 383.04,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sales Overview'), findsOneWidget);
    expect(
      find.text('September 2026 monthly normal, GST and due sales summary'),
      findsOneWidget,
    );
    expect(find.text('Total Bills'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Normal Bill Sales'), findsOneWidget);
    expect(find.text('GST Bill Sales'), findsOneWidget);
    expect(find.text('Due Amount'), findsOneWidget);
    expect(find.text('GST Collected'), findsOneWidget);
    expect(find.text('Normal Bill GST Estimate'), findsOneWidget);
    expect(find.text('Total Taxable Sales'), findsNothing);
    expect(find.text('GST Bill Value'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sales overview hides zero-value smart cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: const Scaffold(
          body: SalesReportSalesOverview(
            periodLabel: 'September 2026',
            summary: SalesReportGstLiabilitySummary(),
          ),
        ),
      ),
    );

    expect(find.text('Normal Bill Sales'), findsNothing);
    expect(find.text('GST Bill Sales'), findsNothing);
    expect(find.text('Due Amount'), findsNothing);
    expect(
      find.text('No sales activity recorded for this month.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
