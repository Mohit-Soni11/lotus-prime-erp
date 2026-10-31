part of 'return_reversal_invoice_summary_panel.dart';

class _ReturnCartMetalBreakdown {
  final String metal;
  var itemCount = 0;
  var netWeight = 0.0;
  var metalAmount = 0.0;
  var availableMaking = 0.0;
  var returnedMaking = 0.0;

  _ReturnCartMetalBreakdown(this.metal);

  double get returnValue => metalAmount + returnedMaking;

  void add(
    ReturnReversalSourceLineItem item,
    Map<int, ReturnReversalLineInspectionDraft> inspectionDrafts,
  ) {
    final draft = _draftFor(item, inspectionDrafts);
    final adjustedMaking = _adjustedMakingAmount(item, inspectionDrafts);

    itemCount += 1;
    netWeight += draft.receivedNetWeight;
    metalAmount += _metalReturnAmount(item, inspectionDrafts);
    availableMaking += adjustedMaking;
    if (draft.includeMakingCharge) {
      returnedMaking += adjustedMaking;
    }
  }
}

class _MetalInvoiceBreakdown {
  final String metal;
  var itemCount = 0;
  var netWeight = 0.0;
  var itemValue = 0.0;
  var makingAmount = 0.0;
  var discountAmount = 0.0;
  var taxableAmount = 0.0;
  var gstAmount = 0.0;
  var invoiceTotal = 0.0;

  _MetalInvoiceBreakdown(this.metal);

  double get gstPercent {
    final taxable = displayTaxableValue;
    if (taxable <= 0 || gstAmount <= 0) {
      return 0;
    }
    return gstAmount / taxable * 100;
  }

  double get displayTaxableValue {
    if (taxableAmount > 0) {
      return taxableAmount;
    }
    return math.max(0.0, itemValue - discountAmount);
  }

  double get displayInvoiceTotal {
    if (invoiceTotal > 0) {
      return invoiceTotal;
    }
    return math.max(0.0, displayTaxableValue + gstAmount);
  }

  void add(ReturnReversalSourceLineItem item) {
    final lineValue = item.displayLineTotal;
    itemCount += 1;
    netWeight += item.netWeight;
    itemValue += lineValue;
    makingAmount += item.makingAmount;
    discountAmount += item.discountAmount;
    taxableAmount += item.taxableAmount;
    gstAmount += item.gstAmount;
    invoiceTotal += item.invoiceValue > 0
        ? item.invoiceValue
        : math.max(0.0, lineValue - item.discountAmount + item.gstAmount);
  }
}

class _MetalSummaryTile extends StatelessWidget {
  final _MetalInvoiceBreakdown breakdown;

  const _MetalSummaryTile(this.breakdown);

  Color get _accentColor {
    return breakdown.metal.contains('GOLD')
        ? SalesPosColors.brandGold
        : SalesPosColors.brandSilver;
  }

  @override
  Widget build(BuildContext context) {
    final metalTitle = _formatMetalName(breakdown.metal);
    final gstLabel = breakdown.gstPercent > 0
        ? 'GST (${_formatPercent(breakdown.gstPercent)})'
        : 'GST';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$metalTitle Pricing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SalesPosStyles.bodyStrong.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCountLabel | ${breakdown.netWeight.toStringAsFixed(3)} g',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SalesPosStyles.caption.copyWith(
                        color: SalesPosColors.textDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatCurrency(breakdown.displayInvoiceTotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.bodyStrong.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SalesPosColors.bodyBorder.withValues(alpha: 0.72),
              ),
            ),
            child: Column(
              children: [
                _SubtleRow(
                  label: '$metalTitle Value',
                  value: _formatCurrency(breakdown.itemValue),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: 'Discount',
                  value: _formatCurrency(breakdown.discountAmount),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: 'Taxable Value',
                  value: _formatCurrency(breakdown.displayTaxableValue),
                ),
                const SizedBox(height: 7),
                _SubtleRow(
                  label: gstLabel,
                  value: _formatCurrency(breakdown.gstAmount),
                ),
                const SizedBox(height: 9),
                _TotalRow(
                  label: '$metalTitle Total',
                  value: _formatCurrency(breakdown.displayInvoiceTotal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get itemCountLabel {
    final suffix = breakdown.itemCount == 1 ? 'item' : 'items';
    return '${breakdown.itemCount} $suffix';
  }
}

class _BookingAdvanceSummaryTile extends StatelessWidget {
  final _MetalInvoiceBreakdown breakdown;

  const _BookingAdvanceSummaryTile(this.breakdown);

  Color get _accentColor {
    return breakdown.metal.contains('GOLD')
        ? SalesPosColors.brandGold
        : SalesPosColors.brandSilver;
  }

  @override
  Widget build(BuildContext context) {
    final metalTitle = _formatMetalName(breakdown.metal);
    final suffix = breakdown.itemCount == 1 ? 'line' : 'lines';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$metalTitle Booking',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.bodyStrong.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${breakdown.itemCount} $suffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.caption.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TotalRow(
            label: 'Advance Received',
            value: _formatCurrency(breakdown.displayInvoiceTotal),
          ),
        ],
      ),
    );
  }
}

class _SelectedReturnCard extends StatelessWidget {
  final bool isBookingCancellation;
  final int selectedCount;
  final List<_ReturnCartMetalBreakdown> breakdowns;

  const _SelectedReturnCard({
    required this.isBookingCancellation,
    required this.selectedCount,
    required this.breakdowns,
  });

  @override
  Widget build(BuildContext context) {
    final totalReturnValue = breakdowns.fold<double>(
      0,
      (total, breakdown) => total + breakdown.returnValue,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
      ),
      child: Column(
        children: [
          _SubtleRow(
            label: isBookingCancellation ? 'Cancellation Lines' : 'Cart Items',
            value: selectedCount.toString(),
          ),
          if (breakdowns.isEmpty) ...[
            const SizedBox(height: 10),
            _EmptySummaryText(
              isBookingCancellation
                  ? 'No booking selected for cancellation.'
                  : 'No return items added to cart.',
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...breakdowns.map(
              (breakdown) => _ReturnCartMetalTile(
                breakdown,
                isBookingCancellation: isBookingCancellation,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _PillarRow(
            label: isBookingCancellation ? 'Refund Value' : 'Return Value',
            value: _formatCurrency(totalReturnValue),
          ),
        ],
      ),
    );
  }
}

class _ReturnCartMetalTile extends StatelessWidget {
  final _ReturnCartMetalBreakdown breakdown;
  final bool isBookingCancellation;

  const _ReturnCartMetalTile(
    this.breakdown, {
    required this.isBookingCancellation,
  });

  Color get _accentColor {
    return breakdown.metal.contains('GOLD')
        ? SalesPosColors.brandGold
        : SalesPosColors.brandSilver;
  }

  @override
  Widget build(BuildContext context) {
    final metalTitle = _formatMetalName(breakdown.metal);
    final suffix = breakdown.itemCount == 1 ? 'item' : 'items';

    if (isBookingCancellation) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SalesPosColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accentColor.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$metalTitle Advance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.bodyStrong.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${breakdown.itemCount} $suffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.caption.copyWith(
                    color: SalesPosColors.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _SubtleRow(
              label: 'Advance Received',
              value: _formatCurrency(breakdown.returnValue),
            ),
            const SizedBox(height: 9),
            _TotalRow(
              label: 'Refund Total',
              value: _formatCurrency(breakdown.returnValue),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$metalTitle Return',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesPosStyles.bodyStrong.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${breakdown.itemCount} $suffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.caption.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _SubtleRow(
            label: '$metalTitle Net Weight',
            value: '${breakdown.netWeight.toStringAsFixed(3)} g',
          ),
          const SizedBox(height: 7),
          _SubtleRow(
            label: '$metalTitle Metal Amount',
            value: _formatCurrency(breakdown.metalAmount),
          ),
          const SizedBox(height: 7),
          _SubtleRow(
            label: '$metalTitle Making Available',
            value: _formatCurrency(breakdown.availableMaking),
          ),
          const SizedBox(height: 7),
          _SubtleRow(
            label: '$metalTitle Making Returned',
            value: _formatCurrency(breakdown.returnedMaking),
          ),
          const SizedBox(height: 9),
          _TotalRow(
            label: '$metalTitle Return Total',
            value: _formatCurrency(breakdown.returnValue),
          ),
        ],
      ),
    );
  }
}

class _MiniSectionLabel extends StatelessWidget {
  final String label;

  const _MiniSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: SalesPosStyles.caption.copyWith(
        color: SalesPosColors.brandGold,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHead({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: SalesPosColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: SalesPosColors.brandGold.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(icon, color: SalesPosColors.brandGold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.highVisHeader,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.bodyText.copyWith(
                  color: SalesPosColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
