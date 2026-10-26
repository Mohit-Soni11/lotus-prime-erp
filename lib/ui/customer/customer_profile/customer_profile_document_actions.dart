part of 'customer_profile_screen.dart';

extension _ProfileDocumentActions on _CustomerProfileScreenState {
  Future<void> _previewBillPdf(
    int billId, {
    SalesInvoicePdfMode mode = SalesInvoicePdfMode.postedOriginal,
  }) async {
    final detail = await _logic.fetchBillDetails(billId);
    if (!mounted) return;
    if (detail == null) {
      _showInfoFeedback('Sales invoice details could not be loaded.');
      return;
    }
    final bytes =
        await _salesPdf.buildSalesInvoicePdf(detail: detail, mode: mode);
    if (!mounted) return;
    if (bytes == null) {
      _showInfoFeedback('Sales invoice PDF could not be generated.');
      return;
    }
    await _showDocumentPreview(pdfBytes: bytes);
  }

  Future<void> _printBillPdf(
    int billId, {
    SalesInvoicePdfMode mode = SalesInvoicePdfMode.postedOriginal,
  }) async {
    final detail = await _logic.fetchBillDetails(billId);
    if (!mounted) return;
    if (detail == null) {
      _showInfoFeedback('Sales invoice details could not be loaded.');
      return;
    }
    final bytes =
        await _salesPdf.buildSalesInvoicePdf(detail: detail, mode: mode);
    if (!mounted) return;
    if (bytes == null) {
      _showInfoFeedback('Sales invoice PDF could not be generated.');
      return;
    }
    await Printing.layoutPdf(
      name: mode == SalesInvoicePdfMode.currentStatement
          ? 'sales_invoice_${detail.bill.billNo}_updated_statement.pdf'
          : 'sales_invoice_${detail.bill.billNo}_original.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _previewLinkedDocumentPdf(
    CustomerLinkedDocumentModel document,
  ) async {
    final bytes = await _relatedPdf.buildLinkedDocumentPdf(document);
    if (!mounted) return;
    await _showDocumentPreview(pdfBytes: bytes);
  }

  Future<void> _printLinkedDocumentPdf(
    CustomerLinkedDocumentModel document,
  ) {
    return Printing.layoutPdf(
      name: '${document.documentNo}_return_settlement.pdf',
      onLayout: (_) => _relatedPdf.buildLinkedDocumentPdf(document),
    );
  }

  Future<void> _previewGirviInvoice(int loanId) async {
    final draft = await _logic.fetchGirviInvoiceDraft(loanId);
    if (!mounted) return;
    if (draft == null) {
      _showInfoFeedback('Girvi receipt details could not be loaded.');
      return;
    }
    final controller = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await controller.generatePreview();
      if (!mounted) return;
      final bytes = controller.pdfBytes;
      if (bytes == null) {
        _showInfoFeedback('Girvi receipt PDF could not be generated.');
        return;
      }
      await _showDocumentPreview(pdfBytes: bytes);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _printGirviInvoice(int loanId) async {
    final draft = await _logic.fetchGirviInvoiceDraft(loanId);
    if (!mounted) return;
    if (draft == null) {
      _showInfoFeedback('Girvi receipt details could not be loaded.');
      return;
    }
    final controller = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      final printed = await controller.printInvoice();
      if (!mounted) return;
      if (!printed) _showInfoFeedback('Girvi receipt could not be printed.');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _previewAdvancePdf(CustomerAdvanceOrderModel order) async {
    final bytes = await _relatedPdf.buildAdvanceOrderPdf(order, _logic.profile);
    if (!mounted) return;
    await _showDocumentPreview(pdfBytes: bytes);
  }

  Future<void> _printAdvancePdf(CustomerAdvanceOrderModel order) {
    return Printing.layoutPdf(
      name: 'advance_order_${order.orderNo}.pdf',
      onLayout: (_) => _relatedPdf.buildAdvanceOrderPdf(order, _logic.profile),
    );
  }

  Future<void> _showCleanPdfPreview({
    required Future<Uint8List> Function(PdfPageFormat format) builder,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: PdfPreview(
                  build: builder,
                  initialPageFormat: PdfPageFormat.a4,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  useActions: false,
                  maxPageWidth: 820,
                  scrollViewDecoration: const BoxDecoration(
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.62),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDocumentPreview({required Uint8List pdfBytes}) async {
    final sides = await _rasterPdfSides(pdfBytes);
    if (!mounted) return;
    if (sides.isEmpty) {
      await _showCleanPdfPreview(builder: (_) async => pdfBytes);
      return;
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Material(
        type: MaterialType.transparency,
        child: CustomerProfileDocumentPreview(
          sides: sides,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<List<PdfRaster>> _rasterPdfSides(Uint8List pdfBytes) async {
    try {
      final info = await Printing.info();
      if (!info.canRaster) return const [];

      final sides = <PdfRaster>[];
      await for (final page in Printing.raster(pdfBytes, dpi: 144)) {
        sides.add(page);
        if (sides.length == 2) break;
      }
      return List.unmodifiable(sides);
    } catch (_) {
      return const [];
    }
  }
}
