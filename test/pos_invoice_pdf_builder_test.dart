import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_pdf_builder.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import 'package:lotus_erp/features/sales_pos/application/services/pos_invoice_scope_service.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_number_formatter.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';

void main() {
  group('PosInvoiceScopeService', () {
    test('creates metal scoped invoices with independent totals', () {
      final gold = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Ring',
        purity: '22KT',
        grossWeight: 8,
        rate: 12000,
      );
      final silver = _saleItem(
        metal: MetalType.silver,
        description: 'Silver Chain',
        purity: '925',
        grossWeight: 10,
        rate: 100,
      );
      final invoice = _invoice(saleItems: [gold, silver]);

      final scoped =
          const PosInvoiceScopeService().scopedInvoicesForAllMetals(invoice);

      expect(scoped, hasLength(2));
      expect(scoped[0].invoiceNumber, 'POS-001-GOLD');
      expect(scoped[0].shopLogoPath, 'C:/Lotus/logo.png');
      expect(scoped[0].shopLogoShape, 'square');
      expect(scoped[0].saleItems, [gold]);
      expect(scoped[0].grossAmount, gold.totalValue);
      expect(scoped[1].invoiceNumber, 'POS-001-SILVER');
      expect(scoped[1].shopLogoPath, 'C:/Lotus/logo.png');
      expect(scoped[1].shopLogoShape, 'square');
      expect(scoped[1].saleItems, [silver]);
      expect(scoped[1].grossAmount, silver.totalValue);

      gold.dispose();
      silver.dispose();
    });
  });

  group('PosInvoicePdfBuilder', () {
    test('generates valid A4 PDF bytes', () async {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Ring',
        purity: '22KT',
        grossWeight: 8,
        rate: 12000,
      );
      final invoice = _invoice(saleItems: [item]);

      final bytes = await const PosInvoicePdfBuilder().build(
        invoice: invoice,
        options: PosInvoicePdfBuildOptions(
          format: PrintFormat.a4,
          copies: 1,
          includeDuplicateStamp: false,
          metalPrintSettings: {MetalType.gold: BillSettings()},
        ),
      );

      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');

      item.dispose();
    });

    test('prints long policy copy on continuation pages', () async {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Ring',
        purity: '22KT',
        grossWeight: 8,
        rate: 12000,
      );
      final invoice = _invoice(saleItems: [item]);
      final longTerms = List.generate(
        80,
        (index) =>
            '${index + 1}. Goods are billed according to the final verified weight, purity and customer-approved settlement terms.',
      ).join('\n');

      final bytes = await const PosInvoicePdfBuilder().build(
        invoice: invoice,
        options: PosInvoicePdfBuildOptions(
          format: PrintFormat.a4,
          copies: 1,
          includeDuplicateStamp: false,
          metalPrintSettings: {
            MetalType.gold: BillSettings(
              termsAndConditions: longTerms,
              printTermsAndConditions: true,
            ),
          },
        ),
      );

      expect(_pdfPageCount(bytes), greaterThan(1));

      item.dispose();
    });
  });
}

int _pdfPageCount(List<int> bytes) {
  final content = String.fromCharCodes(bytes);
  return RegExp(r'/Type\s*/Page\b').allMatches(content).length;
}

SaleItemModel _saleItem({
  required MetalType metal,
  required String description,
  required String purity,
  required double grossWeight,
  required double rate,
}) {
  final item = SaleItemModel(metal: metal);
  item.descCtrl.text = description;
  item.purityCtrl.text = purity;
  item.grossCtrl.text = PosNumberFormatter.compact(grossWeight);
  item.lessCtrl.text = '0';
  item.rateCtrl.text = PosNumberFormatter.compact(rate);
  item.makingCtrl.text = '0';
  return item;
}

PosInvoiceModel _invoice({
  required List<SaleItemModel> saleItems,
}) {
  final grossAmount = saleItems.fold(0.0, (sum, item) => sum + item.totalValue);
  return PosInvoiceModel(
    invoiceNumber: 'POS-001',
    invoiceDate: DateTime(2026, 6, 26),
    billType: BillType.normal,
    billingMode: BillingMode.retail,
    shopName: 'ANJALI JEWELLERS',
    shopAddress: 'Patna',
    shopPhone: '9304479436',
    shopGstin: '',
    shopLogoPath: 'C:/Lotus/logo.png',
    shopLogoShape: 'square',
    customerName: 'Reyansh Soni',
    customerMobile: '9304479436',
    customerCity: 'Patna',
    customerPan: '',
    customerGstin: '',
    oldGoldMode: OldGoldAdjustMode.cashAdjust,
    saleItems: saleItems,
    oldGoldItems: const <OldGoldItemModel>[],
    grossAmount: grossAmount,
    discountAmount: 0,
    taxableAmount: grossAmount,
    cgst: 0,
    sgst: 0,
    totalGst: 0,
    totalOldGoldDeduction: 0,
    grandTotal: grossAmount,
    cashPaid: grossAmount,
    upiPaid: 0,
    cardPaid: 0,
    advancePaid: 0,
    balanceDue: 0,
    totalMakingCharge: 0,
  );
}
