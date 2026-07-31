part of '../../pos_invoice_preview_screen.dart';

extension _PosInvoiceHubActions on _PosInvoicePreviewScreenState {
  Widget _buildActionFooter() {
    final isReady = _invCtrl.genState == InvoiceGenState.ready;
    final hasPhone = _invCtrl.invoice?.customerMobile.isNotEmpty ?? false;
    final isFinalized =
        _invCtrl.isSavedToDb || widget.billingCtrl.isCurrentSaleCommitted;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        border: Border(top: BorderSide(color: SalesPosColors.shellBorder)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SalesPosColors.shellBg.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFinalized
                ? SalesPosColors.success.withValues(alpha: 0.34)
                : SalesPosColors.brandGold.withValues(alpha: 0.34),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InvoiceActionStatus(
              isReady: isReady,
              isFinalized: isFinalized,
              isPrinted: _hasPrintedInvoice,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InvoiceActionButton(
                    label: isFinalized ? 'Share PDF' : 'Finalize & Share',
                    icon: Icons.chat_bubble_rounded,
                    onPressed:
                        isReady && hasPhone ? () => _shareInvoice() : null,
                    accentColor: const Color(0xFF25D366),
                    filled: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InvoiceActionButton(
                    label: _isPdfSaved
                        ? 'Exported'
                        : isFinalized
                            ? 'Export PDF'
                            : 'Finalize & Export',
                    icon: _isPdfSaved
                        ? Icons.check_circle_rounded
                        : Icons.download_rounded,
                    onPressed:
                        isReady && !_isSavingPdf ? () => _exportPdf() : null,
                    isBusy: _isSavingPdf,
                    accentColor: _isPdfSaved
                        ? SalesPosColors.success
                        : SalesPosColors.shellTextTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InvoiceActionButton(
              label: _isPrintingInvoice
                  ? 'Printing'
                  : isFinalized
                      ? 'Print & New Sale'
                      : 'Finalize, Print & New Sale',
              icon: Icons.print_rounded,
              onPressed:
                  isReady && !_isPrintingInvoice ? () => _printInvoice() : null,
              accentColor: SalesPosColors.brandGold,
              filled: true,
              isPrimary: true,
              isBusy: _isPrintingInvoice,
            ),
            const SizedBox(height: 8),
            _InvoiceActionButton(
              label: isFinalized ? 'Start New Sale' : 'Save & New Sale',
              icon: Icons.done_all_rounded,
              onPressed: isReady ? () => _completeAndNewSale() : null,
              accentColor: SalesPosColors.success,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printInvoice() async {
    try {
      _setInvoicePrintState(isPrinting: true);
      final printed = await _invCtrl.printInvoice(
        _invCtrl.selectedFormat,
        context: context,
      );
      if (!mounted) return;
      _setInvoicePrintState(
        isPrinting: false,
        hasPrinted: printed || _hasPrintedInvoice,
      );
      if (printed) {
        widget.billingCtrl.clearEntirePOS();
        if (mounted) {
          Navigator.of(context).pop();
        }
        if (!mounted) return;
        AppFeedback.success(
          context,
          message:
              'Invoice saved and printed successfully. POS is ready for the next customer.',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _setInvoicePrintState(isPrinting: false);
      AppFeedback.error(
        context,
        message: 'Invoice print failed. Please try again.',
      );
    }
  }

  Future<void> _shareInvoice() async {
    try {
      await _invCtrl.shareInvoicePdf();
    } catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: 'Invoice PDF share failed. Please try again.',
      );
    }
  }

  Future<void> _completeAndNewSale() async {
    try {
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
    } catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: 'Could not close this sale. Please try again.',
      );
    }
  }
}

class _InvoiceActionStatus extends StatelessWidget {
  final bool isReady;
  final bool isFinalized;
  final bool isPrinted;

  const _InvoiceActionStatus({
    required this.isReady,
    required this.isFinalized,
    required this.isPrinted,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isPrinted
        ? SalesPosColors.brandGold
        : isFinalized
            ? SalesPosColors.success
            : isReady
                ? SalesPosColors.brandGold
                : SalesPosColors.warning;
    final title = isPrinted
        ? 'Invoice Printed'
        : isFinalized
            ? 'Invoice Finalized'
            : isReady
                ? 'Ready to Finalize'
                : 'Preparing Invoice';
    final subtitle = isPrinted
        ? 'Printed'
        : isFinalized
            ? 'Saved'
            : isReady
                ? 'Draft'
                : 'Please wait';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Icon(
            isPrinted
                ? Icons.local_printshop_rounded
                : isFinalized
                    ? Icons.verified_rounded
                    : isReady
                        ? Icons.receipt_long_rounded
                        : Icons.hourglass_top_rounded,
            color: accent,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INVOICE COMPLETION',
                style: TextStyle(
                  color: SalesPosColors.shellTextMuted,
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SalesPosColors.shellTextTitle,
                  fontSize: SalesPosStyles.fontInput,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: accent,
              fontSize: SalesPosStyles.fontCaption,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool filled;
  final bool isPrimary;
  final bool isBusy;

  const _InvoiceActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.accentColor,
    this.filled = false,
    this.isPrimary = false,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = isPrimary ? 48.0 : 42.0;
    final foreground = filled ? Colors.black : accentColor;
    final background = filled ? accentColor : Colors.transparent;
    final borderColor = onPressed == null
        ? SalesPosColors.shellBorder
        : filled
            ? accentColor
            : accentColor.withValues(alpha: 0.45);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: _buttonIcon(foreground),
              label: _buttonLabel(foreground),
              style: ElevatedButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
                disabledBackgroundColor:
                    SalesPosColors.shellBorder.withValues(alpha: 0.40),
                disabledForegroundColor: SalesPosColors.shellTextMuted,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: _buttonIcon(foreground),
              label: _buttonLabel(foreground),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                disabledForegroundColor: SalesPosColors.shellTextMuted,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
    );
  }

  Widget _buttonIcon(Color color) {
    if (isBusy) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }
    return Icon(icon, size: isPrimary ? 19 : 16);
  }

  Widget _buttonLabel(Color color) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize:
            isPrimary ? SalesPosStyles.fontInput : SalesPosStyles.fontLabel,
        letterSpacing: 0,
      ),
    );
  }
}
