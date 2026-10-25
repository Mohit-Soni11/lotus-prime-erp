import 'dart:typed_data';

import '../../models/girvi/girvi_invoice_draft.dart';
import 'girvi_invoice_hub_controller.dart';

/// The document set shown by Interest Entry and Girvi Account.
/// It uses the existing invoice flow, including its interest and release pages.
class GirviDocumentSetService {
  const GirviDocumentSetService();

  Future<Uint8List> build(GirviInvoiceDraft draft) async {
    final controller = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await controller.generatePreview();
      final bytes = controller.pdfBytes;
      if (bytes == null) {
        throw StateError('Girvi document set could not be generated.');
      }
      return bytes;
    } finally {
      controller.dispose();
    }
  }
}
