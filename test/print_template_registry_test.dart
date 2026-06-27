import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/models/setting/billing_setup/sales_billing_model.dart';

void main() {
  group('PrintTemplateRegistry', () {
    test('registers Lotus Classic as the system default template', () {
      final template = PrintTemplateRegistry.byId(
        PrintTemplateRegistry.defaultTemplateId,
      );

      expect(template.id, TemplateOptions.defaultTemplate);
      expect(template.shortName, 'Lotus Classic');
      expect(template.isSystemDefault, isTrue);
    });

    test('default template supports every billing document family', () {
      const template = PrintTemplateRegistry.lotusClassic;

      for (final type in PrintTemplateDocumentType.values) {
        expect(template.supports(type), isTrue);
      }
    });

    test('unknown template ids fall back to Lotus Classic', () {
      expect(
        PrintTemplateRegistry.byId('missing-template').id,
        PrintTemplateRegistry.defaultTemplateId,
      );
    });

    test('filters templates by document type', () {
      final templates = PrintTemplateRegistry.forDocument(
        PrintTemplateDocumentType.salesInvoice,
      );

      expect(templates, contains(PrintTemplateRegistry.lotusClassic));
      expect(
        templates.every(
          (template) => template.supports(
            PrintTemplateDocumentType.salesInvoice,
          ),
        ),
        isTrue,
      );
    });
  });
}
