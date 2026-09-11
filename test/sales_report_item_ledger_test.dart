import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/sales_report/sales_report_models.dart';
import 'package:lotus_erp/theme/reports/sales_report/sales_report_theme.dart';
import 'package:lotus_erp/ui/report/sales_report/item_ledger/sales_report_item_ledger.dart';

void main() {
  testWidgets('item ledger uses readable professional table labels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SalesReportItemLedger(
              items: [
                _item(
                  billNo: 'AJ-26-012',
                  customerName: 'REYANSH SONI',
                  metalType: 'Gold',
                  itemName: 'Ring',
                  huid: 'ABC123456',
                  purity: '22K',
                  quantity: 2,
                  grossWeight: 12.5,
                  lessWeight: 0.5,
                  netWeight: 12,
                  rate: 7200,
                  makingCharge: 1500,
                  itemTotal: 87900,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sales Item Ledger'), findsOneWidget);
    expect(find.text('S. No.'), findsOneWidget);
    expect(find.text('Bill No'), findsOneWidget);
    expect(find.text('Item Name'), findsOneWidget);
    expect(find.text('Qty'), findsWidgets);
    expect(find.text('Gross Wt'), findsWidgets);
    expect(find.text('Less Wt'), findsOneWidget);
    expect(find.text('Net Wt'), findsWidgets);
    expect(find.text('Line Total'), findsWidgets);
    expect(find.text('S.No'), findsNothing);
    expect(find.text('Invoice'), findsNothing);
    expect(find.text('Gross'), findsNothing);
    expect(find.text('Net'), findsNothing);
    expect(find.text('Total'), findsNothing);

    final billText = tester.widget<Text>(find.text('AJ-26-012'));
    expect(billText.style?.color, SalesReportColors.textPrimary);
    expect(billText.style?.fontSize, 14);
    expect(billText.style?.fontWeight, FontWeight.w900);
    expect(tester.takeException(), isNull);
  });
}

SalesReportItemRow _item({
  required String billNo,
  required String customerName,
  required String metalType,
  required String itemName,
  required String huid,
  required String purity,
  required int quantity,
  required double grossWeight,
  required double lessWeight,
  required double netWeight,
  required double rate,
  required double makingCharge,
  required double itemTotal,
}) {
  return SalesReportItemRow(
    billId: 1,
    billNo: billNo,
    billDate: DateTime(2026, 9, 11, 10, 30),
    customerName: customerName,
    isGst: false,
    lineNo: 1,
    metalType: metalType,
    itemName: itemName,
    huid: huid,
    purity: purity,
    quantity: quantity,
    grossWeight: grossWeight,
    lessWeight: lessWeight,
    netWeight: netWeight,
    fineWeight: netWeight,
    rate: rate,
    makingChargeType: 'fixed',
    makingCharge: makingCharge,
    itemTotal: itemTotal,
    stockSku: '',
    stockCostAmount: 0,
    profitAmount: 0,
  );
}
