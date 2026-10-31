part of 'return_reversal_customer_details_card.dart';

class _SourceDocumentPill extends StatelessWidget {
  final ReturnReversalSourceDocument document;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  const _SourceDocumentPill({
    required this.document,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = switch (document.type) {
      ReturnReversalSourceDocumentType.salesInvoice => SalesPosColors.success,
      ReturnReversalSourceDocumentType.advanceBooking =>
        SalesPosColors.brandGold,
      ReturnReversalSourceDocumentType.customerPurchase =>
        SalesPosColors.brandSilver,
    };
    final hasDue = document.dueAmount > 0.009;
    final hasReversalStatus = document.reversalStatus.trim().isNotEmpty;
    final statusColor = _statusColorFor(document);
    final color = statusColor ?? baseColor;
    final fillColor = selected
        ? color.withValues(alpha: statusColor == null ? 0.13 : 0.11)
        : statusColor == null
            ? Colors.white
            : color.withValues(alpha: 0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          height: _SourceHistoryStripState._documentPillHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color
                  : statusColor != null
                      ? color.withValues(alpha: 0.50)
                      : hasDue
                          ? SalesPosColors.danger.withValues(alpha: 0.55)
                          : SalesPosColors.bodyBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(_iconFor(document.type), size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.documentNo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SalesPosColors.textDark,
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        if (hasDue) ...[
                          const SizedBox(width: 6),
                          const _DueDot(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.type.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: SalesPosStyles.fontCaption,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        if (hasDue) ...[
                          const SizedBox(width: 6),
                          _DueAmountChip(amount: document.dueAmount),
                        ],
                        if (hasReversalStatus)
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(left: hasDue ? 5 : 6),
                              child: _DocumentStatusChip(
                                label: document.reversalStatus,
                                color: statusColor ?? SalesPosColors.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(ReturnReversalSourceDocumentType type) {
    return switch (type) {
      ReturnReversalSourceDocumentType.salesInvoice =>
        Icons.receipt_long_rounded,
      ReturnReversalSourceDocumentType.advanceBooking =>
        Icons.bookmark_added_rounded,
      ReturnReversalSourceDocumentType.customerPurchase => Icons.scale_rounded,
    };
  }

  Color? _statusColorFor(ReturnReversalSourceDocument document) {
    if (document.reversalStatus.trim().isEmpty) {
      return null;
    }
    if (document.isFullyReversed) {
      return SalesPosColors.danger;
    }
    return SalesPosColors.warning;
  }
}

class _DocumentStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DocumentStatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toUpperCase();
    return Container(
      constraints: const BoxConstraints(maxHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        normalized,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DueDot extends StatelessWidget {
  const _DueDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: SalesPosColors.danger,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: SalesPosColors.danger.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _DueAmountChip extends StatelessWidget {
  final double amount;

  const _DueAmountChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: SalesPosColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SalesPosColors.danger.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        'DUE ${_formatCompactCurrency(amount)}',
        style: const TextStyle(
          color: SalesPosColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

String _formatCompactCurrency(double value) {
  final rounded = value.round().abs();
  if (rounded >= 100000) {
    return '${(rounded / 100000).toStringAsFixed(1)}L';
  }
  if (rounded >= 1000) {
    return '${(rounded / 1000).toStringAsFixed(1)}K';
  }
  return rounded.toString();
}
