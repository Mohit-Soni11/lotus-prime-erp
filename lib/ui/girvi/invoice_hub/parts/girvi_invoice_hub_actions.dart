part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceHubActions on _GirviInvoiceHubScreenState {
  Widget _buildActionFooter({bool compact = false}) {
    final isReady = _controller.isReady;
    final ready = isReady && !_controller.isFinalizing;
    final isFinalized = _controller.isFinalized;
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 12 : 14, 16, 16),
      decoration: const BoxDecoration(
        color: GirviColors.shellPanelBg,
        border: Border(top: BorderSide(color: GirviColors.shellBorder)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GirviColors.shellBg.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFinalized
                ? GirviColors.success.withValues(alpha: 0.34)
                : GirviColors.brandGold.withValues(alpha: 0.34),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GirviInvoiceActionStatus(
              isReady: isReady,
              isFinalized: isFinalized,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _GirviInvoiceActionButton(
                    label: isFinalized ? 'Share PDF' : 'Finalize & Share',
                    icon: Icons.chat_bubble_rounded,
                    onPressed:
                        ready && !_controller.isSharing ? _shareInvoice : null,
                    accentColor: const Color(0xFF25D366),
                    filled: true,
                    isBusy: _controller.isSharing,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GirviInvoiceActionButton(
                    label: _exported
                        ? 'Exported'
                        : isFinalized
                            ? 'Export PDF'
                            : 'Finalize & Export',
                    icon: _exported
                        ? Icons.check_circle_rounded
                        : Icons.download_rounded,
                    onPressed: ready && !_controller.isExporting
                        ? _exportInvoice
                        : null,
                    isBusy: _controller.isExporting,
                    accentColor: _exported
                        ? GirviColors.success
                        : GirviColors.shellTextTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _GirviInvoiceActionButton(
              label: isFinalized ? 'Print & Close' : 'Finalize, Print & Close',
              icon: Icons.print_rounded,
              onPressed: ready ? _printInvoice : null,
              accentColor: GirviColors.brandGold,
              filled: true,
              isPrimary: true,
              isBusy: _controller.isFinalizing,
            ),
            const SizedBox(height: 8),
            _GirviInvoiceActionButton(
              label: isFinalized ? 'Close' : 'Save & Close',
              icon: Icons.done_all_rounded,
              onPressed: ready ? _finishGirvi : null,
              accentColor: GirviColors.success,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printInvoice() async {
    try {
      final printed = await _controller.printInvoice(context);
      if (!printed && mounted) {
        _showMessage(
          _controller.errorMessage ?? 'Invoice could not be printed.',
          error: true,
        );
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppFeedback.success(
        context,
        message: 'Girvi invoice saved and printed successfully.',
        duration: const Duration(seconds: 3),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Printer could not be opened. Please try again.',
            error: true);
      }
    }
  }

  Future<void> _shareInvoice() async {
    final shared = await _controller.shareInvoicePdf();
    if (!mounted) return;
    if (!shared) {
      _showMessage(
        _controller.errorMessage ?? 'Invoice PDF share was cancelled.',
        error: true,
      );
      return;
    }
    _showMessage('Girvi invoice PDF is ready to share.');
  }

  Future<void> _exportInvoice() async {
    final path = await _controller.exportPdf();
    if (!mounted) return;
    if (path == null) {
      if (_controller.errorMessage != null) {
        _showMessage(_controller.errorMessage!, error: true);
      }
      return;
    }
    _markExported();
    _showMessage('Girvi invoice PDF exported successfully.');
  }

  Future<void> _finishGirvi() async {
    final finalized = await _controller.finalizeIfNeeded();
    if (!mounted) return;
    if (!finalized) {
      _showMessage(
        _controller.errorMessage ?? 'Girvi ticket could not be saved.',
        error: true,
      );
      return;
    }
    Navigator.of(context).pop(true);
  }
}

class _GirviInvoiceActionStatus extends StatelessWidget {
  const _GirviInvoiceActionStatus({
    required this.isReady,
    required this.isFinalized,
  });

  final bool isReady;
  final bool isFinalized;

  @override
  Widget build(BuildContext context) {
    final accent = isFinalized
        ? GirviColors.success
        : isReady
            ? GirviColors.brandGold
            : GirviColors.warning;
    final title = isFinalized
        ? 'Invoice Finalized'
        : isReady
            ? 'Ready to Finalize'
            : 'Preparing Invoice';
    final subtitle = isFinalized
        ? 'Saved'
        : isReady
            ? 'Review'
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
            isFinalized
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
              Text(
                'INVOICE COMPLETION',
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: GirviColors.shellTextTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
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
            style: GoogleFonts.inter(
              color: accent,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _GirviInvoiceActionButton extends StatelessWidget {
  const _GirviInvoiceActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.accentColor,
    this.filled = false,
    this.isPrimary = false,
    this.isBusy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool filled;
  final bool isPrimary;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final height = isPrimary ? 48.0 : 42.0;
    final foreground = filled ? Colors.black : accentColor;
    final background = filled ? accentColor : Colors.transparent;
    final borderColor = onPressed == null
        ? GirviColors.shellBorder
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
                    GirviColors.shellBorder.withValues(alpha: 0.40),
                disabledForegroundColor: GirviColors.shellTextMuted,
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
                disabledForegroundColor: GirviColors.shellTextMuted,
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
      style: GoogleFonts.inter(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: isPrimary ? 13 : 12.5,
      ),
    );
  }
}
