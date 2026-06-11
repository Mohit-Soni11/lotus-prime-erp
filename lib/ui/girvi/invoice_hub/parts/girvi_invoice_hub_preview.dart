part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceHubPreview on _GirviInvoiceHubScreenState {
  Widget _buildRightPreviewPanel() {
    return Container(
      color: GirviColors.bodyBg,
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            decoration: const BoxDecoration(
              color: GirviColors.cardBg,
              border: Border(
                bottom: BorderSide(color: GirviColors.cardBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: GirviColors.brandGoldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: GirviColors.brandGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BILL REVIEW',
                        style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${widget.draft.ticketNo}  |  ${widget.draft.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: GirviColors.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _previewStatusChip(),
              ],
            ),
          ),
          Expanded(child: _buildPdfPreviewBody()),
        ],
      ),
    );
  }

  Widget _previewStatusChip() {
    final ready = _controller.state == GirviInvoiceHubState.ready;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ready ? GirviColors.successBg : GirviColors.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ready ? GirviColors.successBorder : GirviColors.warningBorder,
        ),
      ),
      child: Text(
        ready ? 'PREVIEW READY' : 'GENERATING',
        style: GoogleFonts.inter(
          color: ready ? GirviColors.success : GirviColors.warning,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildPdfPreviewBody() {
    switch (_controller.state) {
      case GirviInvoiceHubState.idle:
      case GirviInvoiceHubState.generating:
        return const Center(
          child: CircularProgressIndicator(color: GirviColors.brandGold),
        );
      case GirviInvoiceHubState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: GirviColors.danger,
                size: 38,
              ),
              const SizedBox(height: 10),
              Text(
                _controller.errorMessage ?? 'Preview could not be generated.',
                style: GoogleFonts.inter(
                  color: GirviColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _controller.generatePreview,
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      case GirviInvoiceHubState.ready:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PdfPreview(
              key: ValueKey(
                '${_controller.selectedFormat.name}-'
                '${_controller.printCopies}-'
                '${_controller.includeDuplicateStamp}-'
                '${_controller.pdfBytes?.length ?? 0}',
              ),
              build: (_) async => _controller.pdfBytes!,
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              initialPageFormat: _controller.selectedFormat.pageFormat,
            ),
          ),
        );
    }
  }
}
