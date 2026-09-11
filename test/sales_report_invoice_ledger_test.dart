import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/sales_report/sales_report_models.dart';
import 'package:lotus_erp/theme/reports/sales_report/sales_report_theme.dart';
import 'package:lotus_erp/ui/report/sales_report/bill_ledger/sales_report_invoice_ledger.dart';
import 'package:lotus_erp/ui/report/sales_report/sales_report_formatters.dart';

void main() {
  testWidgets('invoice ledger shows clean amount columns with due audit',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SalesReportInvoiceLedger(
              invoices: [
                _invoice(
                  billId: 1,
                  billNo: 'AJ-26-012',
                  customerName: 'REYANSH SONI',
                  mobile: '9876543210',
                  grossAmount: 12768,
                  finalAmount: 12768,
                ),
                _invoice(
                  billId: 2,
                  billNo: 'TAX-AJ-26-013',
                  isGst: true,
                  grossAmount: 10000,
                  gstAmount: 300,
                  finalAmount: 10300,
                  dueAmount: 500,
                ),
              ],
              items: [
                _item(billId: 1, billNo: 'AJ-26-012', metalType: 'SILVER'),
                _item(billId: 2, billNo: 'TAX-AJ-26-013', metalType: 'GOLD'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sales Invoice Ledger'), findsOneWidget);
    expect(find.text('S. No.'), findsOneWidget);
    expect(find.text('Sale Amount'), findsWidgets);
    expect(find.text('Net Total'), findsWidgets);
    expect(find.text('Due Amount'), findsWidgets);
    expect(find.text('No.'), findsNothing);
    expect(find.text('Taxable'), findsNothing);
    expect(find.text('Round Off'), findsNothing);
    expect(find.text('Gross'), findsNothing);
    expect(find.text('Final'), findsNothing);
    expect(find.text('Mobile: 9876543210'), findsOneWidget);
    final dueText = tester.widget<Text>(find.text(salesReportMoney(500)).last);
    expect(dueText.style?.color, const Color(0xFFB91C1C));
    expect(dueText.style?.fontWeight, FontWeight.w900);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invoice ledger hides due column when no invoice is pending',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SalesReportStyles.theme,
        home: Scaffold(
          body: SalesReportInvoiceLedger(
            invoices: [
              _invoice(
                billId: 1,
                billNo: 'AJ-26-012',
                grossAmount: 12768,
                finalAmount: 12768,
              ),
            ],
            items: [
              _item(billId: 1, billNo: 'AJ-26-012', metalType: 'SILVER'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Due Amount'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

SalesReportInvoiceRow _invoice({
  required int billId,
  required String billNo,
  String customerName = 'LOTUS CUSTOMER',
  String mobile = '',
  bool isGst = false,
  double grossAmount = 0,
  double discountAmount = 0,
  double gstAmount = 0,
  double finalAmount = 0,
  double dueAmount = 0,
}) {
  return SalesReportInvoiceRow(
    billId: billId,
    billNo: billNo,
    billDate: DateTime(2026, 9, 11, 10, 30),
    customerName: customerName,
    mobile: mobile,
    billType: isGst ? 'GST' : 'NORMAL',
    paymentStatus: dueAmount > 0 ? 'DUE' : 'PAID',
    isGst: isGst,
    grossAmount: grossAmount,
    discountAmount: discountAmount,
    taxableAmount: grossAmount - discountAmount,
    gstAmount: gstAmount,
    roundOffAmount: 0,
    finalAmount: finalAmount,
    paidAmount: finalAmount - dueAmount,
    dueAmount: dueAmount,
    cashAmount: finalAmount - dueAmount,
    upiAmount: 0,
    cardAmount: 0,
    advanceAmount: 0,
    makingAmount: 0,
    tradeInDeduction: 0,
    itemCount: 1,
    metalMix: isGst ? 'GOLD' : 'SILVER',
  );
}

SalesReportItemRow _item({
  required int billId,
  required String billNo,
  required String metalType,
}) {
  return SalesReportItemRow(
    billId: billId,
    billNo: billNo,
    billDate: DateTime(2026, 9, 11, 10, 30),
    customerName: 'LOTUS CUSTOMER',
    isGst: billNo.startsWith('TAX-'),
    lineNo: 1,
    metalType: metalType,
    itemName: 'RING',
    huid: '',
    purity: '',
    quantity: 1,
    grossWeight: 10,
    lessWeight: 0,
    netWeight: 10,
    fineWeight: 10,
    rate: 0,
    makingChargeType: '',
    makingCharge: 0,
    itemTotal: 0,
    stockSku: '',
    stockCostAmount: 0,
    profitAmount: 0,
  );
}
