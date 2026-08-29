import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_summary/customer_metal_purchase_summary_band.dart';

void main() {
  testWidgets(
      'purchase report summary band shows net weight instead of fine weight',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: CustomerMetalPurchaseReportSummaryBand(
              summary: CustomerMetalPurchaseDashboardSummary(
                grossWeight: 18.5,
                netWeight: 16.12,
                fineWeight: 11.56,
                amount: 175476,
                paidAmount: 57816,
                pendingAmount: 117660,
                cashPaid: 57816,
                upiPaid: 0,
                bankPaid: 0,
                cardPaid: 0,
                entryCount: 12,
                customerCount: 1,
                voucherCount: 6,
              ),
              metalSummaries: {
                CustomerMetalPurchaseMetal.gold:
                    CustomerMetalPurchaseMetalSummary(
                  metal: CustomerMetalPurchaseMetal.gold,
                  grossWeight: 11,
                  netWeight: 10,
                  fineWeight: 8,
                  amount: 120000,
                  paidAmount: 60000,
                  pendingAmount: 60000,
                  cashPaid: 60000,
                  upiPaid: 0,
                  bankPaid: 0,
                  cardPaid: 0,
                  entryCount: 7,
                  customerCount: 1,
                  directPurchaseCount: 7,
                  tradeInCount: 0,
                  refundCount: 0,
                ),
                CustomerMetalPurchaseMetal.silver:
                    CustomerMetalPurchaseMetalSummary(
                  metal: CustomerMetalPurchaseMetal.silver,
                  grossWeight: 8,
                  netWeight: 6.12,
                  fineWeight: 3.56,
                  amount: 55476,
                  paidAmount: 0,
                  pendingAmount: 55476,
                  cashPaid: 0,
                  upiPaid: 0,
                  bankPaid: 0,
                  cardPaid: 0,
                  entryCount: 5,
                  customerCount: 1,
                  directPurchaseCount: 5,
                  tradeInCount: 0,
                  refundCount: 0,
                ),
                CustomerMetalPurchaseMetal.diamond:
                    CustomerMetalPurchaseMetalSummary(
                  metal: CustomerMetalPurchaseMetal.diamond,
                  grossWeight: 0,
                  netWeight: 0,
                  fineWeight: 0,
                  amount: 0,
                  paidAmount: 0,
                  pendingAmount: 0,
                  cashPaid: 0,
                  upiPaid: 0,
                  bankPaid: 0,
                  cardPaid: 0,
                  entryCount: 0,
                  customerCount: 0,
                  directPurchaseCount: 0,
                  tradeInCount: 0,
                  refundCount: 0,
                ),
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Purchase Value'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Net Weight'), findsOneWidget);
    expect(find.text('Fine Weight'), findsNothing);
    expect(find.text('Vouchers'), findsOneWidget);
    expect(find.text('Sellers'), findsOneWidget);
    expect(find.text('16.120 g'), findsOneWidget);
    expect(find.text('Gold'), findsNothing);
    expect(find.text('Metal Split'), findsNothing);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('10.000 g'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('6.120 g'), findsOneWidget);
    expect(find.text('Diamond'), findsNothing);

    final cardHeights = tester
        .widgetList<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.constraints == const BoxConstraints.tightFor(height: 78),
          ),
        )
        .length;
    expect(cardHeights, 6);
  });
}
