part of '../girvi_account_detail_screen.dart';

extension _GirviAccountDocumentActions on _GirviAccountDetailScreenState {
  Future<void> _previewGirviInvoice() async {
    final account = _controller.account;
    if (account == null || _openingGirviInvoice) return;

    _setOpeningGirviInvoice(true);
    try {
      final kind = await _chooseAccountPdfKind(account);
      if (!mounted || kind == null || widget.loanId != account.loan.id) return;
      final bytes = await _buildAccountPdf(account, kind);
      if (!mounted || widget.loanId != account.loan.id) return;

      await _showCleanPdfPreview(
        pdfBytes: bytes,
        allowPrinting: false,
        title: '${kind.title} PDF',
      );
    } on _IssuedInvoiceMissing {
      if (mounted) {
        _showMessage(
            'The original issued invoice PDF is unavailable. Please restore the saved document.');
      }
    } catch (_) {
      if (mounted) _showMessage('Account PDF could not be opened.');
    } finally {
      _setOpeningGirviInvoice(false);
    }
  }

  Future<Uint8List> _buildGirviInvoicePdf(
    GirviLoanWithCustomer account,
  ) async {
    final savedBytes = await const GirviInvoiceDocumentStore().readInvoice(
      loanId: account.loan.id,
      ticketNo: account.loan.ticketNo,
    );
    if (savedBytes == null) throw const _IssuedInvoiceMissing();
    final disposition = GirviRecoveryDisposition.fromDb(
      _controller.recoveryClosure?.disposition,
    );
    const stamp = GirviRecoveryPdfStampService();
    if (disposition != null) return stamp.stamp(savedBytes, disposition);
    if (account.loan.girviStatus == GirviStatus.readyForDelivery ||
        account.loan.girviStatus == GirviStatus.released ||
        account.loan.deliveredAt != null) {
      return stamp.stampReleased(
        savedBytes,
        delivered: account.loan.deliveredAt != null,
      );
    }
    return savedBytes;
  }

  Future<void> _printGirviInvoice() async {
    final account = _controller.account;
    if (account == null || _printingGirviInvoice) return;

    _setPrintingGirviInvoice(true);
    try {
      final kind = await _chooseAccountPdfKind(account, forPrint: true);
      if (!mounted || kind == null || widget.loanId != account.loan.id) return;
      final bytes = await _buildAccountPdf(account, kind);
      if (!mounted || widget.loanId != account.loan.id) return;

      await Printing.layoutPdf(
        name:
            'girvi_${kind.fileSuffix}_${_safePdfName(account.loan.ticketNo)}.pdf',
        onLayout: (_) async => bytes,
      );
    } on _IssuedInvoiceMissing {
      if (mounted) {
        _showMessage(
            'The original issued invoice PDF is unavailable. Please restore the saved document.');
      }
    } catch (_) {
      if (mounted) _showMessage('Account PDF could not be printed.');
    } finally {
      _setPrintingGirviInvoice(false);
    }
  }

  Future<void> _showCleanPdfPreview({
    required Uint8List pdfBytes,
    required bool allowPrinting,
    String? fileName,
    String title = 'Invoice PDF',
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
                key: ValueKey<Uint8List>(pdfBytes),
                build: (_) async => pdfBytes,
                shouldRepaint: true,
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
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    '$title · Double-click a page to zoom',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
