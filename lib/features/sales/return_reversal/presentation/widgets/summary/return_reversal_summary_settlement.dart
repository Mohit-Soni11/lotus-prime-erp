part of 'return_reversal_invoice_summary_panel.dart';

class _PaymentBreakupRow extends StatelessWidget {
  final ReturnReversalSourceDocument? sourceDocument;
  final bool isBookingCancellation;

  const _PaymentBreakupRow({
    required this.sourceDocument,
    required this.isBookingCancellation,
  });

  @override
  Widget build(BuildContext context) {
    final document = sourceDocument;
    if (document == null) {
      return _EmptySummaryText(
        isBookingCancellation
            ? 'Select a booking to view advance payment.'
            : 'Select an invoice to view payments.',
      );
    }
    if (document.type == ReturnReversalSourceDocumentType.advanceBooking) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PaymentChip(label: 'Advance', value: document.paidAmount),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (document.cashPaid > 0)
          _PaymentChip(label: 'Cash', value: document.cashPaid),
        if (document.upiPaid > 0)
          _PaymentChip(label: 'UPI', value: document.upiPaid),
        if (document.cardPaid > 0)
          _PaymentChip(label: 'Card', value: document.cardPaid),
        if (document.advancePaid > 0)
          _PaymentChip(label: 'Advance', value: document.advancePaid),
        if (document.cashPaid <= 0 &&
            document.upiPaid <= 0 &&
            document.cardPaid <= 0 &&
            document.advancePaid <= 0)
          _PaymentChip(label: 'Paid', value: document.paidAmount),
      ],
    );
  }
}

class _PaymentStatusBox extends StatelessWidget {
  final ReturnReversalSourceDocument? sourceDocument;

  const _PaymentStatusBox({required this.sourceDocument});

  @override
  Widget build(BuildContext context) {
    final document = sourceDocument;
    final paidAmount = document?.paidAmount ?? 0;
    final dueAmount = document?.dueAmount ?? 0;
    final isBooking =
        document?.type == ReturnReversalSourceDocumentType.advanceBooking;

    if (document == null) {
      return const _InlineInfoSurface(
        icon: Icons.receipt_long_rounded,
        title: 'Payment Snapshot',
        message: 'Payment details will appear after source selection.',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        children: [
          _SubtleRow(
            label: isBooking ? 'Advance Collected' : 'Collected',
            value: _formatCurrency(paidAmount),
          ),
          const SizedBox(height: 8),
          _SubtleRow(
            label: isBooking ? 'Refund Balance' : 'Balance Due',
            value: _formatCurrency(dueAmount),
          ),
        ],
      ),
    );
  }
}

class _SettlementReadinessStrip extends StatelessWidget {
  final bool isBookingCancellation;
  final ReturnReversalSourceDocument? sourceDocument;
  final int selectedLineCount;
  final double selectedReturnValue;
  final bool isProcessing;
  final bool isPosted;

  const _SettlementReadinessStrip({
    required this.isBookingCancellation,
    required this.sourceDocument,
    required this.selectedLineCount,
    required this.selectedReturnValue,
    required this.isProcessing,
    required this.isPosted,
  });

  @override
  Widget build(BuildContext context) {
    final state = _readinessState;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: state.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: state.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: state.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(state.icon, color: state.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.bodyStrong.copyWith(
                    color: state.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (selectedReturnValue > 0 && !isPosted) ...[
            const SizedBox(width: 10),
            _ReadinessAmountBadge(
              value: 'Ready ${_formatCurrency(selectedReturnValue)}',
            ),
          ],
        ],
      ),
    );
  }

  _ReadinessState get _readinessState {
    if (isProcessing) {
      return const _ReadinessState(
        icon: Icons.sync_rounded,
        title: 'Posting in Progress',
        message: 'Voucher and ledger entries are being saved.',
        color: SalesPosColors.brandGold,
      );
    }
    if (isPosted) {
      return _ReadinessState(
        icon: Icons.verified_rounded,
        title: isBookingCancellation
            ? 'Cancellation Voucher Ready'
            : 'Return Voucher Ready',
        message: isBookingCancellation
            ? 'Cancellation voucher is ready to print or share.'
            : 'Return voucher and invoice copies are ready to print or share.',
        color: SalesPosColors.success,
      );
    }
    if (sourceDocument == null) {
      return _ReadinessState(
        icon: Icons.manage_search_rounded,
        title: isBookingCancellation ? 'Booking Required' : 'Source Required',
        message: isBookingCancellation
            ? 'Select an advance booking before cancellation.'
            : 'Select a sales invoice or purchase voucher before return.',
        color: SalesPosColors.warning,
      );
    }
    if (selectedLineCount <= 0) {
      return _ReadinessState(
        icon: Icons.touch_app_rounded,
        title: isBookingCancellation
            ? 'Cancellation Not Prepared'
            : 'Return Cart Empty',
        message: isBookingCancellation
            ? 'Choose a cancellable booking line to prepare refund.'
            : 'Add pending invoice items to prepare return settlement.',
        color: SalesPosColors.warning,
      );
    }
    return _ReadinessState(
      icon: Icons.task_alt_rounded,
      title: isBookingCancellation ? 'Ready to Cancel' : 'Ready to Process',
      message: isBookingCancellation
          ? '$selectedLineCount booking line selected for refund.'
          : '$selectedLineCount item${selectedLineCount == 1 ? '' : 's'} selected for return.',
      color: SalesPosColors.success,
    );
  }
}

class _ReadinessState {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _ReadinessState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}

class _ReadinessAmountBadge extends StatelessWidget {
  final String value;

  const _ReadinessAmountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SalesPosColors.success.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SalesPosStyles.bodyStrong.copyWith(
          color: SalesPosColors.success,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InlineInfoSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InlineInfoSurface({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: SalesPosColors.brandGold,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.brandGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final double value;

  const _PaymentChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Text(
        '$label ${_formatCurrency(value)}',
        style: SalesPosStyles.caption.copyWith(
          color: SalesPosColors.textDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InvoiceTotalBox extends StatelessWidget {
  final String label;
  final String value;

  const _InvoiceTotalBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: _PillarRow(label: label, value: value),
    );
  }
}

class _EmptySummaryText extends StatelessWidget {
  final String text;

  const _EmptySummaryText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: SalesPosStyles.bodyText.copyWith(
        color: SalesPosColors.textDark,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SubtleRow extends StatelessWidget {
  final String label;
  final String value;

  const _SubtleRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.bodyText.copyWith(
              color: SalesPosColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: SalesPosStyles.bodyStrong.copyWith(
            color: SalesPosColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TotalRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesPosStyles.bodyStrong,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: SalesPosStyles.bodyStrong.copyWith(
              color: SalesPosColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  final String label;
  final String value;

  const _PillarRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.bodyStrong,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: SalesPosColors.brandGold,
            fontSize: SalesPosStyles.fontValue,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SalesPosColors.brandGold.withValues(alpha: 0.05),
            SalesPosColors.bodyBorder,
            SalesPosColors.brandGold.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}
