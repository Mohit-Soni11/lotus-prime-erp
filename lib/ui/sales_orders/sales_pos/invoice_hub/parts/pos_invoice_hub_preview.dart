part of '../../pos_invoice_preview_screen.dart';

extension _PosInvoiceHubPreview on _PosInvoicePreviewScreenState {
  Widget _buildRightPreviewPanel() {
    if (_invCtrl.genState == InvoiceGenState.generating ||
        _invCtrl.genState == InvoiceGenState.idle) {
      return const Center(
        child: CircularProgressIndicator(color: SalesPosColors.brandGold),
      );
    }
    if (_invCtrl.genState == InvoiceGenState.error) {
      return Center(
        child: Text(
          'Error: ${_invCtrl.errorMessage}',
          style: const TextStyle(color: SalesPosColors.danger),
        ),
      );
    }

    final previewKey = ValueKey(
      '${_invCtrl.selectedFormat.name}-${_invCtrl.selectedTemplateId}-${_invCtrl.effectiveActiveMetal?.name ?? 'all'}-${_invCtrl.pdfBytes?.length ?? 0}',
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Padding(
        key: previewKey,
        padding: const EdgeInsets.all(32),
        child: PdfPreview(
          build: (_) async => _invCtrl.pdfBytes!,
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
    switch (_invCtrl.selectedFormat) {
      case PrintFormat.a4:
        return PdfPageFormat.a4;
      case PrintFormat.thermal3inch:
        return const PdfPageFormat(
          80 * PdfPageFormat.mm,
          250 * PdfPageFormat.mm,
        );
      case PrintFormat.thermal2inch:
        return const PdfPageFormat(
          57 * PdfPageFormat.mm,
          250 * PdfPageFormat.mm,
        );
    }
  }
}
