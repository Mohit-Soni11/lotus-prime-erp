import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_financial_breakdown.dart';
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
      expect(scoped[0].invoiceNumber, 'POS-001');
      expect(scoped[0].shopLogoPath, 'C:/Lotus/logo.png');
      expect(scoped[0].shopLogoShape, 'square');
      expect(scoped[0].saleItems, [gold]);
      expect(scoped[0].saleItems.every((item) => item.metal == MetalType.gold),
          isTrue);
      expect(scoped[0].grossAmount, gold.totalValue);
      expect(scoped[1].invoiceNumber, 'POS-001');
      expect(scoped[1].shopLogoPath, 'C:/Lotus/logo.png');
      expect(scoped[1].shopLogoShape, 'square');
      expect(scoped[1].saleItems, [silver]);
      expect(
          scoped[1].saleItems.every((item) => item.metal == MetalType.silver),
          isTrue);
      expect(scoped[1].grossAmount, silver.totalValue);

      gold.dispose();
      silver.dispose();
    });

    test('uses section excess to settle positive metal scoped invoices', () {
      final gold = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Nose Pin',
        purity: '18KT',
        grossWeight: 1,
        rate: 100,
      );
      final silver = _saleItem(
        metal: MetalType.silver,
        description: 'Silver Jantar',
        purity: '60',
        grossWeight: 1,
        rate: 50,
      );
      final silverTradeIn = TradeInItemModel(metal: MetalType.silver);
      silverTradeIn.descCtrl.text = 'Old Silver';
      silverTradeIn.grossCtrl.text = '0.7';
      silverTradeIn.lessCtrl.text = '0';
      silverTradeIn.purityCtrl.text = '100';
      silverTradeIn.rateCtrl.text = '100';
      final invoice = _invoice(
        saleItems: [gold, silver],
        tradeInItems: [silverTradeIn],
      );

      final scoped =
          const PosInvoiceScopeService().scopedInvoicesForAllMetals(invoice);

      expect(scoped, hasLength(2));
      expect(scoped[0].isMetalScopedCopy, isTrue);
      expect(scoped[0].crossMetalAdjustmentDeduction, closeTo(20, 0.01));
      expect(scoped[0].netPayable, closeTo(80, 0.01));
      expect(scoped[0].cashPaid, closeTo(80, 0.01));
      expect(scoped[0].balanceDue, closeTo(0, 0.01));
      expect(scoped[1].netPayable, closeTo(-20, 0.01));
      expect(scoped[1].cashPaid, closeTo(0, 0.01));

      gold.dispose();
      silver.dispose();
      silverTradeIn.dispose();
    });
  });

  group('PosInvoicePdfBuilder', () {
    test('builds selected metal only across every A4 invoice template',
        () async {
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

      for (final template in [
        PrintTemplateRegistry.lotusClassic,
        PrintTemplateRegistry.lotusEconomy,
        PrintTemplateRegistry.lotusSignature,
      ]) {
        for (final metal in [MetalType.gold, MetalType.silver]) {
          final scoped = const PosInvoiceScopeService().scopedInvoiceForMetal(
            invoice,
            metal,
          );

          expect(scoped.invoiceNumber, invoice.invoiceNumber);
          expect(scoped.saleItems, hasLength(1));
          expect(scoped.saleItems.single.metal, metal);

          final bytes = await const PosInvoicePdfBuilder().build(
            invoice: invoice,
            options: PosInvoicePdfBuildOptions(
              format: PrintFormat.a4,
              copies: 1,
              includeDuplicateStamp: false,
              templateId: template.id,
              activeMetal: metal,
              metalPrintSettings: {
                MetalType.gold: BillSettings(),
                MetalType.silver: BillSettings(),
              },
            ),
          );

          expect(bytes.length, greaterThan(1000));
          expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        }
      }

      gold.dispose();
      silver.dispose();
    });

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

    test('generates valid A4 PDF bytes with Lotus Economy template', () async {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Nose Pin',
        purity: '18KT',
        grossWeight: 0.562,
        rate: 11400,
      );
      item.makingCtrl.text = '12';
      final invoice = _invoice(
        saleItems: [item],
        billType: BillType.gst,
        cgst: 107.63,
        sgst: 107.63,
        totalGst: 215.26,
      );

      final bytes = await const PosInvoicePdfBuilder().build(
        invoice: invoice,
        options: PosInvoicePdfBuildOptions(
          format: PrintFormat.a4,
          copies: 1,
          includeDuplicateStamp: false,
          templateId: PrintTemplateRegistry.lotusEconomy.id,
          metalPrintSettings: {
            MetalType.gold: BillSettings(
              showHsnCode: true,
              showMakingType: true,
            ),
          },
        ),
      );

      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');

      item.dispose();
    });

    test('generates valid A4 PDF bytes with Lotus Signature template',
        () async {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Nose Pin',
        purity: '18KT',
        grossWeight: 0.562,
        rate: 11400,
      );
      item.makingCtrl.text = '12';
      final invoice = _invoice(
        saleItems: [item],
        billType: BillType.gst,
        cgst: 107.63,
        sgst: 107.63,
        totalGst: 215.26,
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

      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');

      item.dispose();
    });

    test('Lotus Signature prints enabled policy settings on policy pages',
        () async {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Kada',
        purity: '22KT',
        grossWeight: 12,
        rate: 11800,
      );
      final invoice = _invoice(saleItems: [item]);

      final withoutPolicies = await const PosInvoicePdfBuilder().build(
        invoice: invoice,
        options: PosInvoicePdfBuildOptions(
          format: PrintFormat.a4,
          copies: 1,
          includeDuplicateStamp: false,
          templateId: PrintTemplateRegistry.lotusSignature.id,
          metalPrintSettings: {MetalType.gold: BillSettings()},
        ),
      );
      final withPolicies = await const PosInvoicePdfBuilder().build(
        invoice: invoice,
        options: PosInvoicePdfBuildOptions(
          format: PrintFormat.a4,
          copies: 1,
          includeDuplicateStamp: false,
          templateId: PrintTemplateRegistry.lotusSignature.id,
          metalPrintSettings: {
            MetalType.gold: BillSettings(
              termsAndConditions:
                  'Weight and purity are verified before billing.\nWarranty follows the approved store policy.',
              buybackPolicyText:
                  'Buyback is subject to current purity verification.',
              printTermsAndConditions: true,
              printBuybackPolicy: true,
            ),
          },
        ),
      );

      expect(_pdfPageCount(withoutPolicies), 1);
      expect(_pdfPageCount(withPolicies), greaterThan(1));

      item.dispose();
    });

    test('generates full thermal receipt bytes for 80mm and 57mm formats',
        () async {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Ring',
        purity: '22KT',
        grossWeight: 8,
        rate: 12000,
      );
      final oldMetal = TradeInItemModel(metal: MetalType.gold);
      oldMetal.descCtrl.text = 'Old Gold';
      oldMetal.grossCtrl.text = '2';
      oldMetal.lessCtrl.text = '0';
      oldMetal.purityCtrl.text = '100';
      oldMetal.rateCtrl.text = '11000';
      final invoice = _invoice(
        saleItems: [item],
        tradeInItems: [oldMetal],
      );

      for (final format in [
        PrintFormat.thermal3inch,
        PrintFormat.thermal2inch,
      ]) {
        final bytes = await const PosInvoicePdfBuilder().build(
          invoice: invoice,
          options: PosInvoicePdfBuildOptions(
            format: format,
            copies: 1,
            includeDuplicateStamp: false,
            metalPrintSettings: {MetalType.gold: BillSettings()},
          ),
        );

        expect(bytes.length, greaterThan(1000));
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      }

      item.dispose();
      oldMetal.dispose();
    });
  });

  group('PosInvoiceFinancialBreakdown', () {
    test('uses exact payment modes and due status from invoice data', () {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Ring',
        purity: '22KT',
        grossWeight: 8,
        rate: 12000,
      );
      final invoice = _invoice(
        saleItems: [item],
        cashPaid: 12000,
        upiPaid: 2500,
        cardPaid: 0,
        advancePaid: 500,
        balanceDue: 750,
      );

      final payments = PosInvoiceFinancialBreakdown.payments(invoice);
      expect(payments.map((entry) => entry.label), [
        'Cash',
        'UPI / Bank Transfer',
        'Customer Advance',
      ]);
      expect(payments.map((entry) => entry.amount), [12000, 2500, 500]);

      final status = PosInvoiceFinancialBreakdown.status(invoice);
      expect(status.label, 'DUE');
      expect(status.isDue, isTrue);

      item.dispose();
    });

    test('builds smart amount summary rows only for applicable values', () {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Ring',
        purity: '22KT',
        grossWeight: 8,
        rate: 12000,
      );
      final invoice = _invoice(
        saleItems: [item],
        billType: BillType.gst,
        cgst: 90,
        sgst: 90,
        totalGst: 180,
      );

      final labels = PosInvoiceFinancialBreakdown.summaryRows(
        invoice,
        showGstBreakup: true,
      ).map((row) => row.label);

      expect(labels, containsAll(['Gross Sale Value', 'Taxable Value']));
      expect(labels, containsAll(['CGST', 'SGST', 'Net Payable']));
      expect(labels, isNot(contains('Invoice Discount')));
      expect(labels, isNot(contains('Customer Metal Settlement')));
      expect(labels, isNot(contains('IGST')));

      item.dispose();
    });

    test('shows customer metal settlement summary from transaction data', () {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Ring',
        purity: '22KT',
        grossWeight: 8,
        rate: 12000,
      );
      final oldMetal = TradeInItemModel(metal: MetalType.gold);
      oldMetal.descCtrl.text = 'Old Gold';
      oldMetal.grossCtrl.text = '2';
      oldMetal.lessCtrl.text = '0';
      oldMetal.purityCtrl.text = '100';
      oldMetal.rateCtrl.text = '1000';
      final invoice = _invoice(
        saleItems: [item],
        tradeInItems: [oldMetal],
      );

      final visibleLabels = PosInvoiceFinancialBreakdown.summaryRows(
        invoice,
        showGstBreakup: true,
      ).map((row) => row.label);
      final settlementRow = PosInvoiceFinancialBreakdown.summaryRows(
        invoice,
        showGstBreakup: true,
      ).firstWhere((row) => row.label == 'Customer Metal Settlement');

      expect(visibleLabels, contains('Customer Metal Settlement'));
      expect(settlementRow.amount, invoice.totalTradeInDeduction);

      item.dispose();
      oldMetal.dispose();
    });

    test('uses IGST and hides CGST SGST for interstate tax snapshots', () {
      final item = _saleItem(
        metal: MetalType.gold,
        description: 'Gold Ring',
        purity: '22KT',
        grossWeight: 8,
        rate: 12000,
      );
      final invoice = _invoice(
        saleItems: [item],
        billType: BillType.gst,
        cgst: 0,
        sgst: 0,
        totalGst: 180,
      );

      final labels = PosInvoiceFinancialBreakdown.summaryRows(
        invoice,
        showGstBreakup: true,
      ).map((row) => row.label);

      expect(labels, contains('IGST'));
      expect(labels, isNot(contains('CGST')));
      expect(labels, isNot(contains('SGST')));

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
  List<TradeInItemModel> tradeInItems = const <TradeInItemModel>[],
  BillType billType = BillType.normal,
  double cgst = 0,
  double sgst = 0,
  double totalGst = 0,
  double? cashPaid,
  double upiPaid = 0,
  double cardPaid = 0,
  double advancePaid = 0,
  double balanceDue = 0,
}) {
  final grossAmount = saleItems.fold(0.0, (sum, item) => sum + item.totalValue);
  final tradeInDeduction =
      tradeInItems.fold(0.0, (sum, item) => sum + item.totalValue);
  final grandTotal = grossAmount + totalGst;
  final netPayable = grandTotal - tradeInDeduction;
  return PosInvoiceModel(
    invoiceNumber: 'POS-001',
    invoiceDate: DateTime(2026, 6, 26),
    billType: billType,
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
    tradeInMode: TradeInAdjustMode.cashAdjust,
    saleItems: saleItems,
    tradeInItems: tradeInItems,
    grossAmount: grossAmount,
    discountAmount: 0,
    taxableAmount: grossAmount,
    cgst: cgst,
    sgst: sgst,
    totalGst: totalGst,
    totalTradeInDeduction: tradeInDeduction,
    grandTotal: grandTotal,
    cashPaid: cashPaid ?? netPayable,
    upiPaid: upiPaid,
    cardPaid: cardPaid,
    advancePaid: advancePaid,
    balanceDue: balanceDue,
    totalMakingCharge: 0,
  );
}
