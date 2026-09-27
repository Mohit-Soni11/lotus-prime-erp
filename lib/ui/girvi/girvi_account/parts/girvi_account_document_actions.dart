part of '../girvi_account_detail_screen.dart';

extension _GirviAccountDocumentActions on _GirviAccountDetailScreenState {
  Future<void> _previewGirviInvoice() async {
    final account = _controller.account;
    if (account == null || _openingGirviInvoice) return;

    _setOpeningGirviInvoice(true);
    try {
      final bytes = await _buildGirviInvoicePdf(account);
      if (!mounted) return;

      await _showGirviInvoicePreview(pdfBytes: bytes);
    } catch (_) {
      if (mounted) _showMessage('Girvi invoice could not be opened.');
    } finally {
      _setOpeningGirviInvoice(false);
    }
  }

  Future<Uint8List> _buildGirviInvoicePdf(
    GirviLoanWithCustomer account,
  ) async {
    if (account.loan.invoiceGenerated) {
      final savedBytes = await const GirviInvoiceDocumentStore().readInvoice(
        loanId: account.loan.id,
        ticketNo: account.loan.ticketNo,
      );
      if (savedBytes != null) return savedBytes;
    }

    final draft =
        await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
      customerId: account.loan.customerId,
      loanId: account.loan.id,
    );
    if (draft == null) {
      throw StateError('Girvi invoice draft could not be loaded.');
    }

    final invoiceController = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await invoiceController.generatePreview();
      final bytes = invoiceController.pdfBytes;
      if (bytes == null) {
        throw StateError('Girvi invoice PDF could not be generated.');
      }
      return bytes;
    } finally {
      invoiceController.dispose();
    }
  }

  Future<void> _showGirviInvoicePreview({required Uint8List pdfBytes}) async {
    final sides = await _rasterPdfSides(pdfBytes);
    if (!mounted) return;
    if (sides.isEmpty) {
      return _showCleanPdfPreview(
        pdfBytes: pdfBytes,
        allowPrinting: false,
      );
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      useSafeArea: false,
      builder: (dialogContext) => Material(
        type: MaterialType.transparency,
        child: _GirviInvoiceFlipPreview(
          sides: sides,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<void> _printPaymentRecord() async {
    final account = _controller.account;
    if (account == null || _printingPaymentRecord) return;

    _setPrintingPaymentRecord(true);
    try {
      final bytes = await _buildPaymentRecordPdf(account);
      if (!mounted) return;

      await Printing.layoutPdf(
        name: 'girvi_payment_record_${_safePdfName(account.loan.ticketNo)}.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (mounted) _showMessage('Payment record could not be printed.');
    } finally {
      _setPrintingPaymentRecord(false);
    }
  }

  Future<void> _previewPaymentRecord() async {
    final account = _controller.account;
    if (account == null || _viewingPaymentRecord) return;

    _setViewingPaymentRecord(true);
    try {
      final bytes = await _buildPaymentRecordPdf(account);
      if (!mounted) return;

      await _showPaymentRecordPreview(
        pdfBytes: bytes,
        fileName:
            'girvi_payment_record_${_safePdfName(account.loan.ticketNo)}.pdf',
      );
    } catch (_) {
      if (mounted) _showMessage('Payment record could not be opened.');
    } finally {
      _setViewingPaymentRecord(false);
    }
  }

  Future<Uint8List> _buildPaymentRecordPdf(
    GirviLoanWithCustomer account,
  ) async {
    final branding = await GirviInvoiceBrandingRepository(db: _db).fetch();
    return GirviPaymentRecordPdfService().build(
      account: account,
      payments: _controller.payments,
      details: _controller.details,
      branding: branding,
    );
  }

  Future<void> _showPaymentRecordPreview({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final sides = await _rasterPdfSides(pdfBytes);
    if (!mounted) return;
    if (sides.isNotEmpty) {
      return showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.78),
        useSafeArea: false,
        builder: (dialogContext) => Material(
          type: MaterialType.transparency,
          child: _GirviInvoiceFlipPreview(
            sides: sides,
            singleSideLabel: 'Payment record preview',
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
    }

    return _showCleanPdfPreview(
      pdfBytes: pdfBytes,
      allowPrinting: true,
      fileName: fileName,
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

  Future<void> _showCleanPdfPreview({
    required Uint8List pdfBytes,
    required bool allowPrinting,
    String? fileName,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.74),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                initialPageFormat: PdfPageFormat.a4,
                allowPrinting: allowPrinting,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: allowPrinting,
                pdfFileName: fileName,
                maxPageWidth: 860,
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
    );
  }
}
