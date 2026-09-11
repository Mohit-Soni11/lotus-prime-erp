import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/sales_report/sales_report_models.dart';
import 'package:lotus_erp/theme/reports/sales_report/sales_report_theme.dart';
import 'package:lotus_erp/ui/report/sales_report/summary/sales_report_grade_summary.dart';

void main() {
  testWidgets('grade summary uses readable professional metric labels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SalesReportGradeSummaryPanel(
              invoices: [
                _invoice(
                  billId: 1,
                  billNo: 'AJ-26-001',
                  finalAmount: 25000,
                ),
                _invoice(
                  billId: 2,
                  billNo: 'TAX-AJ-26-002',
                  isGst: true,
                  gstAmount: 900,
                  finalAmount: 30900,
                ),
              ],
              items: [
                _item(
                  billId: 1,
                  billNo: 'AJ-26-001',
                  purity: '22K',
                  quantity: 2,
                  netWeight: 10,
                  itemTotal: 25000,
                ),
                _item(
                  billId: 2,
                  billNo: 'TAX-AJ-26-002',
                  isGst: true,
                  purity: '22K',
                  quantity: 1,
                  netWeight: 5,
                  itemTotal: 30000,
                ),
              ],
              selectedGrade: allSalesReportGrades,
              onGradeSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Grade-wise Sales'), findsOneWidget);
    expect(find.text('22K Grade'), findsOneWidget);
    expect(find.text('Bills With Grade'), findsOneWidget);
    expect(find.text('Total Qty'), findsOneWidget);
    expect(find.text('Net Weight Sold'), findsOneWidget);
    expect(find.text('GST Collected'), findsOneWidget);
    expect(find.text('Normal GST Estimate'), findsOneWidget);
    expect(find.text('Sales + GST View'), findsOneWidget);
    expect(find.text('Invoices'), findsNothing);
    expect(find.text('Pieces'), findsNothing);
    expect(find.text('GST Total'), findsNothing);
    expect(find.text('Projected GST'), findsNothing);
    expect(find.text('Sale + GST View'), findsNothing);

    final metricLabel = tester.widget<Text>(find.text('Bills With Grade'));
    expect(metricLabel.style?.color, SalesReportColors.textPrimary);
    expect(metricLabel.style?.fontSize, 13.5);
    expect(metricLabel.style?.fontWeight, FontWeight.w900);
    expect(tester.takeException(), isNull);
  });
}

SalesReportInvoiceRow _invoice({
  required int billId,
  required String billNo,
  bool isGst = false,
  double gstAmount = 0,
  double finalAmount = 0,
}) {
  return SalesReportInvoiceRow(
    billId: billId,
    billNo: billNo,
    billDate: DateTime(2026, 9, 11, 10, 30),
    customerName: 'LOTUS CUSTOMER',
    mobile: '',
    billType: isGst ? 'GST' : 'NORMAL',
    paymentStatus: 'PAID',
    isGst: isGst,
    grossAmount: finalAmount - gstAmount,
    discountAmount: 0,
    taxableAmount: finalAmount - gstAmount,
    gstAmount: gstAmount,
    roundOffAmount: 0,
    finalAmount: finalAmount,
    paidAmount: finalAmount,
    dueAmount: 0,
    cashAmount: finalAmount,
    upiAmount: 0,
    cardAmount: 0,
    advanceAmount: 0,
    makingAmount: 0,
    tradeInDeduction: 0,
    itemCount: 1,
    metalMix: 'GOLD',
  );
}

SalesReportItemRow _item({
  required int billId,
  required String billNo,
  required String purity,
  required int quantity,
  required double netWeight,
  required double itemTotal,
  bool isGst = false,
}) {
  return SalesReportItemRow(
    billId: billId,
    billNo: billNo,
    billDate: DateTime(2026, 9, 11, 10, 30),
    customerName: 'LOTUS CUSTOMER',
    isGst: isGst,
    lineNo: 1,
    metalType: 'Gold',
    itemName: 'Ring',
    huid: '',
    purity: purity,
    quantity: quantity,
    grossWeight: netWeight,
    lessWeight: 0,
    netWeight: netWeight,
    fineWeight: netWeight,
    rate: 0,
    makingChargeType: 'fixed',
    makingCharge: 0,
    itemTotal: itemTotal,
    gstRatePercent: 3,
    stockSku: '',
    stockCostAmount: 0,
    profitAmount: 0,
  );
}
