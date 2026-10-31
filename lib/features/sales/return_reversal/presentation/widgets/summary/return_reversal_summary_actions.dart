part of 'return_reversal_invoice_summary_panel.dart';

class _SummaryActions extends StatelessWidget {
  final ReturnReversalController controller;

  const _SummaryActions({required this.controller});

  String get _buttonLabel {
    return controller.state.operationType ==
            ReturnReversalOperationType.salesReturn
        ? 'Process Return'
        : 'Process Cancellation';
  }

  String _voucherButtonLabel(ReturnReversalState state) {
    if (state.selectedSourceDocument == null) {
      return state.operationType.isBookingCancellation
          ? 'Select Booking First'
          : 'Select Source First';
    }
    if (!state.hasReturnCartLineItems &&
        !state.invoiceLineItems.any((lineItem) => lineItem.isReversed) &&
        state.lastProcessResult == null) {
      return state.operationType.isBookingCancellation
          ? 'Prepare Cancellation First'
          : 'Add Return Item First';
    }
    return state.operationType.isBookingCancellation
        ? 'Generate Cancellation Voucher'
        : 'Generate Return Voucher';
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final canProcess = state.hasReturnCartLineItems && !state.isProcessing;
    final hasReturnedLines =
        state.invoiceLineItems.any((lineItem) => lineItem.isReversed);
    final canGenerateVoucher = state.selectedSourceDocument != null &&
        !state.isProcessing &&
        (state.hasReturnCartLineItems ||
            hasReturnedLines ||
            state.lastProcessResult != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.processMessage != null) ...[
          _ProcessMessageBar(
            message: state.processMessage!,
            success: true,
          ),
          const SizedBox(height: 10),
        ],
        if (state.errorMessage != null) ...[
          _ProcessMessageBar(
            message: state.errorMessage!,
            success: false,
          ),
          const SizedBox(height: 10),
        ],
        _PrimarySummaryButton(
          label: _buttonLabel,
          enabled: canProcess,
          isProcessing: state.isProcessing,
          onPressed: controller.processReturn,
        ),
        const SizedBox(height: 10),
        _SecondarySummaryButton(
          label: _voucherButtonLabel(state),
          enabled: canGenerateVoucher,
          onPressed: () {
            ReturnReversalVoucherPreviewScreen.push(
              context,
              controller: controller,
            );
          },
        ),
      ],
    );
  }
}

class _PrimarySummaryButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final bool isProcessing;
  final VoidCallback onPressed;

  const _PrimarySummaryButton({
    required this.label,
    required this.enabled,
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  State<_PrimarySummaryButton> createState() => _PrimarySummaryButtonState();
}

class _PrimarySummaryButtonState extends State<_PrimarySummaryButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled || widget.isProcessing;
    final foreground = active
        ? SalesPosColors.textDark
        : SalesPosColors.textDark.withValues(alpha: 0.74);
    return SizedBox(
      height: 50,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: Listener(
            onPointerDown:
                widget.enabled ? (_) => setState(() => _pressed = true) : null,
            onPointerUp:
                widget.enabled ? (_) => setState(() => _pressed = false) : null,
            onPointerCancel:
                widget.enabled ? (_) => setState(() => _pressed = false) : null,
            child: AnimatedScale(
              scale: _pressed ? 0.985 : 1,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? widget.onPressed : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: active
                          ? LinearGradient(
                              colors: [
                                SalesPosColors.goldGradientStart,
                                _hovered
                                    ? SalesPosColors.goldHoverDark
                                    : SalesPosColors.brandGold,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: active
                          ? null
                          : SalesPosColors.brandGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: SalesPosColors.brandGold.withValues(
                          alpha: active ? 0.92 : 0.54,
                        ),
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: SalesPosColors.brandGold.withValues(
                                  alpha: _hovered ? 0.42 : 0.30,
                                ),
                                blurRadius: _hovered ? 20 : 15,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.36),
                                blurRadius: 5,
                                offset: const Offset(0, -1),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: SalesPosColors.brandGold.withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isProcessing)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: foreground,
                              ),
                            )
                          else
                            Icon(
                              Icons.assignment_turned_in_rounded,
                              color: active
                                  ? foreground
                                  : SalesPosColors.brandGold,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.isProcessing ? 'Posting' : widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SalesPosStyles.buttonText.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessMessageBar extends StatelessWidget {
  final String message;
  final bool success;

  const _ProcessMessageBar({
    required this.message,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? SalesPosColors.success : SalesPosColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.caption.copyWith(
                color: SalesPosColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondarySummaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _SecondarySummaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.receipt_long_rounded, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          animationDuration: const Duration(milliseconds: 140),
          textStyle: WidgetStatePropertyAll(
            SalesPosStyles.buttonText.copyWith(fontWeight: FontWeight.w900),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SalesPosColors.textDark.withValues(alpha: 0.72);
            }
            return SalesPosColors.textDark;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SalesPosColors.bodyPanelBg.withValues(alpha: 0.76);
            }
            if (states.contains(WidgetState.pressed)) {
              return SalesPosColors.brandGold.withValues(alpha: 0.18);
            }
            if (states.contains(WidgetState.hovered)) {
              return SalesPosColors.brandGold.withValues(alpha: 0.10);
            }
            return SalesPosColors.bodyPanelBg;
          }),
          overlayColor: WidgetStatePropertyAll(
            SalesPosColors.brandGold.withValues(alpha: 0.08),
          ),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SalesPosColors.textDark.withValues(alpha: 0.56);
            }
            return SalesPosColors.brandGold;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: SalesPosColors.bodyBorder.withValues(alpha: 0.92),
                width: 1.5,
              );
            }
            return BorderSide(
              color: SalesPosColors.brandGold.withValues(alpha: 0.70),
              width: 1.5,
            );
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          shadowColor: WidgetStatePropertyAll(
            SalesPosColors.brandGold.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }
}

String _formatMetalName(String metal) {
  final normalized = metal.trim().toUpperCase();
  if (normalized.isEmpty) {
    return 'Other';
  }
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty
          ? word
          : '${word.substring(0, 1)}${word.substring(1).toLowerCase()}')
      .join(' ');
}

double _receivedWeightRatio(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  if (lineItem.netWeight <= 0) {
    return 1;
  }
  final receivedWeight = inspectionDrafts[lineItem.lineNo]?.receivedNetWeight ??
      lineItem.netWeight;
  return (receivedWeight / lineItem.netWeight).clamp(0.0, 1.0);
}

ReturnReversalLineInspectionDraft _draftFor(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return inspectionDrafts[lineItem.lineNo] ??
      ReturnReversalLineInspectionDraft.fromLine(lineItem);
}

double _adjustedLineAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return lineItem.displayLineTotal *
      _receivedWeightRatio(lineItem, inspectionDrafts);
}

double _adjustedMakingAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return lineItem.makingAmount *
      _receivedWeightRatio(lineItem, inspectionDrafts);
}

double _metalReturnAmount(
  ReturnReversalSourceLineItem lineItem,
  Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
) {
  return math.max(
    0.0,
    _adjustedLineAmount(lineItem, inspectionDrafts) -
        _adjustedMakingAmount(lineItem, inspectionDrafts),
  );
}

String _formatPercent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) {
    return '${rounded.toStringAsFixed(0)}%';
  }
  return '${value.toStringAsFixed(2)}%';
}

String _formatCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().round().toString();
  if (digits.length <= 3) {
    return 'Rs $sign$digits';
  }
  final lastThree = digits.substring(digits.length - 3);
  final leading = digits.substring(0, digits.length - 3);
  final groupedLeading = leading.replaceAllMapped(
    RegExp(r'\B(?=(\d{2})+(?!\d))'),
    (_) => ',',
  );
  return 'Rs $sign$groupedLeading,$lastThree';
}
