part of '../../pos_invoice_preview_screen.dart';

extension _PosInvoiceHubActions on _PosInvoicePreviewScreenState {
  Widget _buildActionFooter() {
    final isReady = _invCtrl.genState == InvoiceGenState.ready;
    final hasPhone = _invCtrl.invoice?.customerMobile.isNotEmpty ?? false;
    final isFinalized =
        _invCtrl.isSavedToDb || widget.billingCtrl.isCurrentSaleCommitted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        border: Border(top: BorderSide(color: SalesPosColors.shellBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isReady && hasPhone
                      ? _invCtrl.openDirectWhatsAppChat
                      : null,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: const Text(
                    'Share WhatsApp',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SalesPosStyles.fontLabel,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      (isReady && !_isSavingPdf) ? () => _exportPdf() : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isPdfSaved
                        ? SalesPosColors.success
                        : SalesPosColors.shellTextTitle,
                    side: BorderSide(
                      color: _isPdfSaved
                          ? SalesPosColors.success
                          : SalesPosColors.shellBorder,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSavingPdf
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SalesPosColors.brandGold,
                            ),
                          )
                        : _isPdfSaved
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                key: ValueKey('saved'),
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: SalesPosColors.success,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Exported',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: SalesPosStyles.fontLabel,
                                      color: SalesPosColors.success,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                key: ValueKey('idle'),
                                children: [
                                  Icon(Icons.download_rounded, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Export PDF',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: SalesPosStyles.fontLabel,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: ElevatedButton.icon(
                onPressed: isReady
                    ? () => _invCtrl.printInvoice(_invCtrl.selectedFormat)
                    : null,
                icon: const Icon(Icons.print_rounded, size: 20),
                label: Text(
                  isFinalized ? 'PRINT INVOICE' : 'FINALIZE & PRINT',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: SalesPosStyles.fontInput,
                    letterSpacing: 0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SalesPosColors.brandGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isReady
                  ? () async {
                      await _invCtrl.finalizeInvoiceIfNeeded();
                      if (!mounted) return;
                      widget.billingCtrl.clearEntirePOS();
                      Navigator.of(context).pop();
                      AppFeedback.show(
                        context,
                        type: AppFeedbackType.success,
                        message:
                            'Invoice finalized successfully. POS is ready for the next customer.',
                        duration: const Duration(seconds: 3),
                      );
                    }
                  : null,
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: const Text(
                'COMPLETE & NEW SALE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: SalesPosStyles.fontInput,
                  letterSpacing: 0,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: SalesPosColors.success,
                side: const BorderSide(
                  color: SalesPosColors.success,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
