import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/print_templates/application/print_template_preview_pdf_service.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrintTemplatePreviewPdfService', () {
    test('builds valid preview PDFs for supported document types', () async {
      final service = PrintTemplatePreviewPdfService();
      const template = PrintTemplateRegistry.lotusClassic;

      for (final documentType in [
        PrintTemplateDocumentType.salesInvoice,
        PrintTemplateDocumentType.girviReceipt,
      ]) {
        final bytes = await service.build(
          template: template,
          documentType: documentType,
        );

        expect(bytes.length, greaterThan(1000));
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      }
    });
  });
}
