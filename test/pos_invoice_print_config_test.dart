import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_print_config.dart';
import 'package:lotus_erp/features/sales_pos/application/pdf/pos_invoice_template_renderer_registry.dart';
import 'package:lotus_erp/models/setting/billing_setup/sales_billing_model.dart';

void main() {
  group('BillSettings', () {
    test('keeps saved sales print flags when loading billing setup', () {
      final model = SalesBillingModel.defaultFor(BillingMetal.gold).copyWith(
        printTermsAndConditions: true,
        printReturnPolicy: true,
        printBuybackPolicy: true,
        printFooterMessage: false,
      );

      final settings = BillSettings.fromSalesBilling(model);

      expect(settings.printTermsAndConditions, isTrue);
      expect(settings.printReturnPolicy, isTrue);
      expect(settings.printBuybackPolicy, isTrue);
      expect(settings.printFooterMessage, isFalse);
    });

    test('uses Billing Setup footer copy as the print source', () {
      final model = SalesBillingModel.defaultFor(BillingMetal.gold);

      final settings = BillSettings.fromSalesBilling(model);

      expect(
        settings.footerMessage,
        contains('This is a computer generated tax invoice.'),
      );
      expect(settings.footerMessage, model.footerMessage);
    });
  });

  group('PosInvoiceTemplateRendererRegistry', () {
    test('has an A4 renderer for every registered sales invoice template', () {
      final templates = PrintTemplateRegistry.forDocument(
        PrintTemplateDocumentType.salesInvoice,
      );

      for (final template in templates) {
        expect(
          PosInvoiceTemplateRendererRegistry.hasA4Renderer(template.id),
          isTrue,
          reason: '${template.id} must have a Sales A4 renderer.',
        );
      }
    });
  });
}
