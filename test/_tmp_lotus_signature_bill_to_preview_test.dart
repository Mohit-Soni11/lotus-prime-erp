import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_pdf_builder.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_number_formatter.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';

void main() {
  test('renders Lotus Signature bill-to preview PDF', () async {
    final item = SaleItemModel(metal: MetalType.gold);
    item.descCtrl.text = 'NOSE PIN';
    item.setInvoiceHsnCode('71131910');
    item.purityCtrl.text = '18KT';
    item.grossCtrl.text = PosNumberFormatter.compact(0.356);
    item.lessCtrl.text = '0';
    item.rateCtrl.text = PosNumberFormatter.compact(11400);
    item.makingCtrl.text = '12';

    final invoice = PosInvoiceModel(
      invoiceNumber: 'AJ-26-007',
      invoiceDate: DateTime(2026, 8, 20),
      billType: BillType.gst,
      billingMode: BillingMode.retail,
      shopName: 'ANJALI JEWELLERS',
      shopAddress:
          'EAST LAKSHMI NAGAR, KHEMNICHAK, PATNA, BIHAR - 800027',
      shopPhone: '9304479436',
      shopGstin: '10AAGFF2194N1Z1',
      customerName: 'REYANSH SONI SONI',
      customerMobile: '9304479436',
      customerCity: 'EAST LAKSHMI NAGAR, PATNA, Bihar - 800027',
      customerGstin: '10AAGFF2194N1Z1',
      customerPan: '',
      tradeInMode: TradeInAdjustMode.cashAdjust,
      saleItems: [item],
      tradeInItems: const [],
      grossAmount: 4545.41,
      discountAmount: 100,
      taxableAmount: 4445.41,
      cgst: 66.68,
      sgst: 66.68,
      totalGst: 133.36,
      totalTradeInDeduction: 0,
      grandTotal: 4578.77,
      cashPaid: 4000,
      upiPaid: 0,
      cardPaid: 0,
      advancePaid: 0,
      balanceDue: 578.77,
      totalMakingCharge: 0,
      promiseDate: DateTime(2026, 8, 31),
    );

    final bytes = await const PosInvoicePdfBuilder().build(
      invoice: invoice,
      options: PosInvoicePdfBuildOptions(
        format: PrintFormat.a4,
        copies: 1,
        includeDuplicateStamp: false,
        templateId: PrintTemplateRegistry.lotusSignature.id,
        metalPrintSettings: {
          MetalType.gold: BillSettings(
            showHsnCode: true,
            showMakingType: true,
          ),
        },
      ),
    );

    final output = File(
      'build/debug-previews/lotus_signature_bill_to_preview.pdf',
    );
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes, flush: true);

    expect(bytes.length, greaterThan(1000));
    item.dispose();
  });
}
