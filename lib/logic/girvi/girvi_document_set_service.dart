import 'dart:typed_data';

import '../../models/girvi/girvi_invoice_draft.dart';
import 'girvi_invoice_document_store.dart';
import 'girvi_invoice_hub_controller.dart';
import 'girvi_invoice_pdf_service.dart';
import 'girvi_pdf_document_assembler.dart';
import 'girvi_receipt_financial_summary.dart';

/// The document set shown by Interest Entry and Girvi Account.
/// It uses the existing invoice flow, including its interest and release pages.
class GirviDocumentSetService {
  const GirviDocumentSetService({
    GirviInvoiceDocumentStore? documentStore,
    GirviPdfDocumentAssembler? assembler,
    GirviInvoicePdfService? pdfService,
  })  : _documentStore = documentStore,
        _assembler = assembler,
        _pdfService = pdfService;

  final GirviInvoiceDocumentStore? _documentStore;
  final GirviPdfDocumentAssembler? _assembler;
  final GirviInvoicePdfService? _pdfService;

  Future<Uint8List> build(
    GirviInvoiceDraft draft, {
    bool requireSavedInvoice = false,
  }) async {
    final issuedInvoice =
        await (_documentStore ?? const GirviInvoiceDocumentStore()).readInvoice(
      loanId: draft.loanId,
      ticketNo: draft.ticketNo,
    );
    if (issuedInvoice != null) {
      final hasReceipts = GirviReceiptFinancialSummary.fromDraft(draft)
              .interestEntries
              .isNotEmpty ||
          draft.isReleaseReceipt;
      if (!hasReceipts &&
          draft.recoveryDisposition == null &&
          !draft.isReleaseReceipt &&
          draft.deliveredAt == null) {
        return issuedInvoice;
      }
      final appendix = hasReceipts
          ? await (_pdfService ?? GirviInvoicePdfService())
              .buildLifecycleAppendix(draft: draft)
          : null;
      return (_assembler ?? const GirviPdfDocumentAssembler()).assemble(
        issuedInvoice: issuedInvoice,
        appendix: appendix,
        draft: draft,
      );
    }
    if (requireSavedInvoice) {
      throw StateError('The saved original invoice PDF is unavailable.');
    }
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
