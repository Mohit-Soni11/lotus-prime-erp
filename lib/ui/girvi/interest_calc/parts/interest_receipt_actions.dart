part of '../interest_calc_screen.dart';

extension InterestReceiptActions on _InterestCalcScreenState {
  void _setPaymentAmount(double value) {
    final nextValue = _formatEntryAmountInput(value);
    _syncingText = true;
    _setText(_amountCtrl, nextValue);
    _syncingText = false;
    _ctrl.onAmountChanged(nextValue);
  }

  String _formatEntryAmountInput(double value) {
    if (value <= 0) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<void> _previewGirviDocumentSet(GirviLoanWithCustomer data) async {
    if (_openingReceipt) return;
    _setOpeningReceipt(true);
    try {
      final bytes = await _buildStoredGirviDocumentSetPdf(data);
      if (!mounted) return;
      if (bytes == null) {
        _showInfoFeedback('Girvi document details could not be loaded.');
        return;
      }

      await _showGirviReleaseDocumentPreview(
        pdfBytes: bytes,
        fileName: _girviDocumentSetFileName(data.loan.ticketNo),
      );
    } catch (_) {
      if (mounted) {
        _showInfoFeedback('Girvi document preview could not be opened.');
      }
    } finally {
      _setOpeningReceipt(false);
    }
  }

  Future<Uint8List?> _buildStoredGirviDocumentSetPdf(
    GirviLoanWithCustomer data,
  ) async {
    final draft =
        await CustomerProfileRepository(db: _db).fetchGirviInvoiceDraft(
      customerId: data.loan.customerId,
      loanId: data.loan.id,
    );
    if (draft == null) return null;

    final controller = GirviInvoiceHubController(
      draft: draft,
      onFinalize: () async => true,
    );
    try {
      await controller.generatePreview();
      return controller.pdfBytes;
    } finally {
      controller.dispose();
    }
  }

  String _girviDocumentSetFileName(String ticketNo) {
    final safeTicket = ticketNo.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '_');
    return 'girvi_document_$safeTicket.pdf';
  }

  void _showInfoFeedback(String message) {
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
    );
  }
}
