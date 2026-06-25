part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceHubActions on _GirviInvoiceHubScreenState {
  Widget _buildActionFooter({bool compact = false}) {
    final ready = _controller.isReady && !_controller.isFinalizing;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: const BoxDecoration(
        color: GirviColors.shellPanelBg,
        border: Border(top: BorderSide(color: GirviColors.shellBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      ready && !_controller.isExporting ? _exportInvoice : null,
                  icon: _controller.isExporting
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GirviColors.brandGold,
                          ),
                        )
                      : Icon(
                          _exported
                              ? Icons.check_circle_rounded
                              : Icons.download_rounded,
                          size: 16,
                        ),
                  label: Text(_exported ? 'Exported' : 'Export PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _exported
                        ? GirviColors.success
                        : GirviColors.shellTextTitle,
                    side: BorderSide(
                      color: _exported
                          ? GirviColors.success
                          : GirviColors.shellBorder,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: ready ? _finishGirvi : null,
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Finish'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GirviColors.success,
                    side: const BorderSide(color: GirviColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ready ? _printInvoice : null,
              icon: _controller.isFinalizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GirviColors.shellBg,
                      ),
                    )
                  : const Icon(Icons.print_rounded, size: 19),
              label: Text(
                _controller.isFinalized ? 'PRINT INVOICE' : 'FINALIZE & PRINT',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: GirviColors.brandGold,
                foregroundColor: GirviColors.shellBg,
                disabledBackgroundColor:
                    GirviColors.brandGold.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice() async {
    try {
      final printed = await _controller.printInvoice();
      if (!printed && mounted) {
        _showMessage(
          _controller.errorMessage ?? 'Invoice could not be printed.',
          error: true,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Printer could not be opened. Please try again.',
            error: true);
      }
    }
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
