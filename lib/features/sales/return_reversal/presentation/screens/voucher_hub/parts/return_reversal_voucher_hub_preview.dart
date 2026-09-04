part of '../../return_reversal_voucher_preview_screen.dart';

extension _ReturnReversalVoucherHubPreview
    on _ReturnReversalVoucherPreviewScreenState {
  Widget _buildRightPreviewPanel() {
    if (_voucherCtrl.genState == ReturnReversalVoucherGenState.generating ||
        _voucherCtrl.genState == ReturnReversalVoucherGenState.idle) {
      return const Center(
        child: CircularProgressIndicator(color: SalesPosColors.brandGold),
      );
    }
    if (_voucherCtrl.genState == ReturnReversalVoucherGenState.error) {
      return Center(
        child: Text(
          'Error: ${_voucherCtrl.errorMessage}',
          style: const TextStyle(color: SalesPosColors.danger),
        ),
      );
    }

    final previewKey = ValueKey(
      '${_voucherCtrl.selectedFormat.name}-'
      '${_voucherCtrl.selectedOutputDocument.name}-'
      '${_voucherCtrl.selectedInvoiceScopeLabel}-'
      '${_voucherCtrl.selectedTemplateId}-'
      '${_voucherCtrl.printCopies}-'
      '${_voucherCtrl.includeDuplicateStamp}-'
      '${_voucherCtrl.pdfBytes?.length ?? 0}',
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Padding(
        key: previewKey,
        padding: const EdgeInsets.all(32),
        child: PdfPreview(
          build: (_) async => _voucherCtrl.pdfBytes!,
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          initialPageFormat: _getPageFormat(),
        ),
      ),
    );
  }

  PdfPageFormat _getPageFormat() {
    return ReturnReversalVoucherPdfService.pageFormatFor(
      _voucherCtrl.selectedFormat,
    );
  }
}
