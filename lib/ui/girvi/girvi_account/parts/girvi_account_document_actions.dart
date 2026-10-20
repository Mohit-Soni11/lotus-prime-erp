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
    } on _IssuedInvoiceMissing {
      if (mounted) {
        _showMessage(
            'The original issued invoice PDF is unavailable. Please restore the saved document.');
      }
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
      throw const _IssuedInvoiceMissing();
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
    return _showCleanPdfPreview(
      pdfBytes: pdfBytes,
      allowPrinting: false,
    );
  }

  Future<void> _printGirviInvoice() async {
    final account = _controller.account;
    if (account == null || _printingGirviInvoice) return;

    _setPrintingGirviInvoice(true);
    try {
      final bytes = await _buildGirviInvoicePdf(account);
      if (!mounted) return;

      await Printing.layoutPdf(
        name: 'girvi_invoice_${_safePdfName(account.loan.ticketNo)}.pdf',
        onLayout: (_) async => bytes,
      );
    } on _IssuedInvoiceMissing {
      if (mounted) {
        _showMessage(
            'The original issued invoice PDF is unavailable. Please restore the saved document.');
      }
    } catch (_) {
      if (mounted) _showMessage('Girvi invoice could not be printed.');
    } finally {
      _setPrintingGirviInvoice(false);
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
                dpi: 200,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF111827),
                ),
                onError: (context, error) => const Center(
                  child: Text(
                    'PDF preview could not be displayed.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    'Invoice PDF · Double-click a page to zoom',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
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

class _IssuedInvoiceMissing implements Exception {
  const _IssuedInvoiceMissing();
}
