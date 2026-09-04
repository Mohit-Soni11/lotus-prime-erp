part of '../../return_reversal_voucher_preview_screen.dart';

extension _ReturnReversalVoucherHubActions
    on _ReturnReversalVoucherPreviewScreenState {
  Widget _buildActionFooter() {
    final isReady = _voucherCtrl.isReady;
    final documentLabel = _voucherCtrl.selectedOutputDocumentLabel;
    final isPosted = widget.controller.isCurrentWorkspacePosted;
    final flowLabel = _newWorkspaceLabel;

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
            color: _hasPrintedVoucher
                ? SalesPosColors.success.withValues(alpha: 0.34)
                : SalesPosColors.brandGold.withValues(alpha: 0.34),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VoucherActionStatus(
              isReady: isReady,
              isPosted: isPosted,
              isPrinted: _hasPrintedVoucher,
              isExported: _isPdfSaved,
              documentLabel: documentLabel,
              flowLabel: flowLabel,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _VoucherActionButton(
                    label: 'Share PDF',
                    icon: Icons.chat_bubble_rounded,
                    onPressed: isReady ? () => _shareVoucher() : null,
                    accentColor: const Color(0xFF25D366),
                    filled: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _VoucherActionButton(
                    label: _isPdfSaved ? 'Exported' : 'Export PDF',
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
            _VoucherActionButton(
              label: _isPrintingVoucher
                  ? 'Printing'
                  : 'Print Document & $flowLabel',
              icon: Icons.print_rounded,
              onPressed: isReady && !_isPrintingVoucher
                  ? () => _printDocumentAndStartNew()
                  : null,
              accentColor: SalesPosColors.brandGold,
              filled: true,
              isPrimary: true,
              isBusy: _isPrintingVoucher,
            ),
            const SizedBox(height: 8),
            _VoucherActionButton(
              label: _isCompletingWorkspace ? 'Saving' : 'Save & $flowLabel',
              icon: Icons.done_all_rounded,
              onPressed: isReady && !_isCompletingWorkspace
                  ? () => _saveAndStartNew()
                  : null,
              accentColor: SalesPosColors.success,
              isPrimary: true,
              isBusy: _isCompletingWorkspace,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    _setVoucherSavingState(isSaving: true);
    final path = await _voucherCtrl.exportVoucherPdf();
    if (!mounted) return;
    _setVoucherSavingState(isSaving: false, isSaved: path != null);
    if (path == null) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _setVoucherSavingState(isSaved: false);
    });
    AppFeedback.success(
      context,
      message:
          '${_voucherCtrl.selectedOutputDocumentLabel} exported successfully.',
    );
  }

  Future<void> _shareVoucher() async {
    try {
      final shared = await _voucherCtrl.shareVoucherPdf();
      if (!mounted || shared) return;
      AppFeedback.error(
        context,
        message:
            '${_voucherCtrl.selectedOutputDocumentLabel} share was cancelled.',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message:
            '${_voucherCtrl.selectedOutputDocumentLabel} PDF share failed. Please try again.',
      );
    }
  }

  String get _newWorkspaceLabel {
    return widget.controller.state.operationType.isBookingCancellation
        ? 'New Cancellation'
        : 'New Return';
  }

  Future<bool> _postWorkspaceForIssue() async {
    final posted = await widget.controller.postCurrentWorkspaceIfNeeded();
    if (!mounted) return false;
    if (!posted) {
      AppFeedback.error(
        context,
        message: widget.controller.state.errorMessage ??
            widget.controller.state.lookupMessage ??
            'Could not save this ${_newWorkspaceLabel.toLowerCase()}. Please review the workflow.',
      );
      return false;
    }
    await _voucherCtrl.generateVoucher();
    return mounted && _voucherCtrl.isReady;
  }

  void _startFreshWorkspace(String message) {
    widget.controller.startNewWorkspace();
    Navigator.of(context).pop();
    AppFeedback.success(
      context,
      message: message,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _printDocumentAndStartNew() async {
    try {
      _setVoucherPrintState(isPrinting: true);
      final posted = await _postWorkspaceForIssue();
      if (!mounted) return;
      if (!posted) {
        _setVoucherPrintState(isPrinting: false);
        return;
      }
      final printed = await _voucherCtrl.printVoucher(context);
      if (!mounted) return;
      _setVoucherPrintState(
        isPrinting: false,
        hasPrinted: printed || _hasPrintedVoucher,
      );
      if (printed) {
        _startFreshWorkspace(
          '${_voucherCtrl.selectedOutputDocumentLabel} saved and printed successfully. Return desk is ready for $_newWorkspaceLabel.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _setVoucherPrintState(isPrinting: false);
      AppFeedback.error(
        context,
        message:
            '${_voucherCtrl.selectedOutputDocumentLabel} print failed. Please try again.',
      );
    }
  }

  Future<void> _saveAndStartNew() async {
    try {
      _setWorkspaceCompletionState(true);
      final posted = await _postWorkspaceForIssue();
      if (!mounted) return;
      _setWorkspaceCompletionState(false);
      if (!posted) return;
      _startFreshWorkspace(
        '${_voucherCtrl.selectedOutputDocumentLabel} saved successfully. Return desk is ready for $_newWorkspaceLabel.',
      );
    } catch (_) {
      if (!mounted) return;
      _setWorkspaceCompletionState(false);
      AppFeedback.error(
        context,
        message:
            'Could not save this ${_newWorkspaceLabel.toLowerCase()}. Please try again.',
      );
    }
  }
}

class _VoucherActionStatus extends StatelessWidget {
  final bool isReady;
  final bool isPosted;
  final bool isPrinted;
  final bool isExported;
  final String documentLabel;
  final String flowLabel;

  const _VoucherActionStatus({
    required this.isReady,
    required this.isPosted,
    required this.isPrinted,
    required this.isExported,
    required this.documentLabel,
    required this.flowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isPrinted
        ? SalesPosColors.brandGold
        : isPosted
            ? SalesPosColors.success
            : isExported
                ? SalesPosColors.success
                : isReady
                    ? SalesPosColors.brandGold
                    : SalesPosColors.warning;
    final title = isPrinted
        ? 'Document Printed'
        : isPosted
            ? '${flowLabel.replaceFirst('New ', '')} Saved'
            : isExported
                ? 'Document Exported'
                : isReady
                    ? 'Ready to Save'
                    : 'Preparing Document';
    final subtitle = isPrinted
        ? 'Printed'
        : isPosted
            ? 'Saved'
            : isExported
                ? 'Exported'
                : isReady
                    ? 'Ready'
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
                : isPosted
                    ? Icons.verified_rounded
                    : isExported
                        ? Icons.download_done_rounded
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
                'DOCUMENT OUTPUT',
                style: TextStyle(
                  color: SalesPosColors.shellTextMuted,
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$title - $documentLabel',
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

class _VoucherActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool filled;
  final bool isPrimary;
  final bool isBusy;

  const _VoucherActionButton({
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
