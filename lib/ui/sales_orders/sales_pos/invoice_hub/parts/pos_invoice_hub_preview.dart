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

    if (_invCtrl.hasMultipleMetalInvoices && !_invCtrl.isIssuedPdfSaved) {
      return _buildCachedMetalPreviews();
    }

    final previewKey = ValueKey(_invCtrl.pdfBytes);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Padding(
        key: previewKey,
        padding: const EdgeInsets.all(32),
        child: PosInvoiceCachedPdfPane(
          bytes: _invCtrl.pdfBytes!,
          pageFormat: _getPageFormat(),
        ),
      ),
    );
  }

  Widget _buildCachedMetalPreviews() {
    final previews = _invCtrl.readyMetalPreviews;
    final metals = _invCtrl.presentMetals
        .where(previews.containsKey)
        .toList(growable: false);
    if (metals.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: SalesPosColors.brandGold),
      );
    }

    final selectedMetal = _invCtrl.effectiveActiveMetal;
    final selectedIndex = metals.indexOf(selectedMetal!);
    return Stack(
      fit: StackFit.expand,
      children: [
        IndexedStack(
          index: selectedIndex < 0 ? 0 : selectedIndex,
          children: [
            for (final metal in metals)
              Padding(
                key: ValueKey('invoice-preview-${metal.name}'),
                padding: const EdgeInsets.all(32),
                child: PosInvoiceCachedPdfPane(
                  key: ValueKey(previews[metal]),
                  bytes: previews[metal]!,
                  pageFormat: _getPageFormat(),
                ),
              ),
          ],
        ),
        if (selectedIndex < 0)
          ColoredBox(
            color: SalesPosColors.bodyBg.withValues(alpha: 0.92),
            child: const Center(
              child: CircularProgressIndicator(color: SalesPosColors.brandGold),
            ),
          ),
      ],
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
          marginAll: 4 * PdfPageFormat.mm,
        );
      case PrintFormat.thermal2inch:
        return const PdfPageFormat(
          57 * PdfPageFormat.mm,
          250 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        );
    }
  }
}
