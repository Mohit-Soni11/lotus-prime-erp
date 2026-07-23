part of '../../inventory_screen.dart';

class _InventoryBatchCard extends StatelessWidget {
  final _InventoryBatchGroup batch;
  final StockMetalUiData ui;
  final VoidCallback onTap;

  const _InventoryBatchCard({
    required this.batch,
    required this.ui,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _batchStatusColor();
    final statusBg = _batchStatusBg();
    final soldOut = batch.isSoldOut;
    final needsReconciliation = batch.hasScaleVariance;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: soldOut || needsReconciliation
            ? const Color(0xFFFFFBFA)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: soldOut || needsReconciliation
              ? statusColor.withValues(alpha: 0.28)
              : InvColors.cardBorder,
          width: soldOut || needsReconciliation ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ((soldOut || needsReconciliation) ? statusColor : ui.accent)
                .withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: ui.gradient,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(ui.icon, color: ui.textOnGradient, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            batch.batchCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: InvColors.textDark,
                            ),
                          ),
                        ),
                        if (batch.isGst) ...[
                          const SizedBox(width: 10),
                          _GstTag(accent: ui.accent),
                        ],
                        const SizedBox(width: 10),
                        _BatchStatusTag(
                          label: batch.stockStatusLabel,
                          color: statusColor,
                          background: statusBg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _batchSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Invoice Items: ${batch.sourceItemPreview}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: InvColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              _BatchMetric(
                label: 'Invoice Items',
                value:
                    '${batch.sourceInvoiceItemCount} item${batch.sourceInvoiceItemCount == 1 ? '' : 's'}',
                accent: statusColor,
                helper: '${batch.quantityBalanceLabel} in view',
              ),
              _BatchMetric(
                label: 'Gross Weight',
                value: '${_weight(batch.totalGrossWeight)} g',
                accent: ui.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _batchSubtitle() {
    final parts = [
      batch.supplierName.isEmpty
          ? 'Supplier not linked'
          : 'Supplier: ${batch.supplierName}',
      if (batch.supplierInvoiceNo.isNotEmpty)
        'Invoice: ${batch.supplierInvoiceNo}',
      if (batch.createdAt > 0) 'Purchase Date: ${_date(batch.createdAt)}',
    ];
    return parts.join(' - ');
  }

  Color _batchStatusColor() {
    if (batch.hasScaleVariance) return const Color(0xFFF59E0B);
    if (batch.isSoldOut) return InvColors.danger;
    if (batch.isPartiallySold) return const Color(0xFFF59E0B);
    return InvColors.success;
  }

  Color _batchStatusBg() {
    if (batch.hasScaleVariance) return const Color(0xFFFFF7E6);
    if (batch.isSoldOut) return InvColors.dangerBg;
    if (batch.isPartiallySold) return const Color(0xFFFFF7E6);
    return InvColors.successBg;
  }

  String _date(int millis) {
    return DateFormat('dd MMM yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }
}

class _InventoryGradeUnitCard extends StatelessWidget {
  final _InventoryGradeUnit unit;
  final StockMetalUiData ui;

  const _InventoryGradeUnitCard({
    required this.unit,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = unit.stockMovementStatusLabel;
    final statusColor = _unitStatusColor(statusLabel);
    final statusBg = _unitStatusBg(statusLabel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  unit.itemName.isEmpty ? 'Unnamed Stock Item' : unit.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _itemSubtitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _UnitMetric(label: 'Unit', value: unit.displayUnitPlural),
              _UnitMetric(label: 'Total Qty', value: unit.totalQuantityLabel),
              _UnitMetric(
                  label: 'Available', value: unit.availableQuantityLabel),
              _UnitMetric(label: 'Sold', value: unit.soldQuantityLabel),
              if (unit.huid.isNotEmpty)
                _UnitMetric(label: 'HUID', value: unit.huid),
              if (_hasWeightDifference(
                  unit.displayTotalGrossWeight, unit.displayTotalNetWeight))
                _UnitMetric(
                    label: 'Gross Weight',
                    value: '${_weight(unit.displayTotalGrossWeight)} g'),
              _UnitMetric(
                  label: 'Total Weight',
                  value: '${_weight(unit.displayTotalNetWeight)} g'),
              if (unit.displayAvailableNetWeight > 0)
                _UnitMetric(
                    label: 'Available Weight',
                    value: '${_weight(unit.displayAvailableNetWeight)} g'),
              if (unit.soldNetWeight > 0)
                _UnitMetric(
                    label: 'Sold Weight',
                    value: '${_weight(unit.soldNetWeight)} g'),
              if (unit.hasScaleVariance)
                _UnitMetric(
                    label: 'Scale Variance', value: unit.scaleVarianceLabel),
              if (unit.purityPercent > 0)
                _UnitMetric(
                    label: 'Base Purity',
                    value: '${_percent(unit.purityPercent)}%'),
              if (unit.wastagePercent > 0)
                _UnitMetric(
                    label: 'Wastage',
                    value: '${_percent(unit.wastagePercent)}%'),
              if (unit.totalPurityPercent > 0)
                _UnitMetric(
                    label: 'Valuation Purity',
                    value: '${_percent(unit.totalPurityPercent)}%'),
              if (unit.actualFine > 0)
                _UnitMetric(
                    label: 'Actual Fine',
                    value: '${_weight(unit.actualFine)} g'),
              if (unit.valuationFine > 0)
                _UnitMetric(
                  label: 'Valuation Fine',
                  value: '${_weight(unit.valuationFine)} g',
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _itemSubtitle() {
    final parts = [
      unit.companyName,
      unit.itemType,
      unit.segment,
      unit.unitCode,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'Stock unit' : parts.join(' - ');
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }

  Color _unitStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('reconciliation')) return const Color(0xFFF59E0B);
    if (normalized.contains('partially')) return const Color(0xFFF59E0B);
    if (normalized.contains('sold')) return InvColors.danger;
    return InvColors.success;
  }

  Color _unitStatusBg(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('reconciliation')) return const Color(0xFFFFF7E6);
    if (normalized.contains('partially')) return const Color(0xFFFFF7E6);
    if (normalized.contains('sold')) return InvColors.dangerBg;
    return InvColors.successBg;
  }
}

class _BatchMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final String? helper;

  const _BatchMetric({
    required this.label,
    required this.value,
    required this.accent,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 80,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 2),
            Text(
              helper!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: InvColors.textDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchStatusTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _BatchStatusTag({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _UnitMetric extends StatelessWidget {
  final String label;
  final String value;

  const _UnitMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 106),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7DAC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GstTag extends StatelessWidget {
  final Color accent;

  const _GstTag({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        'GST',
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: accent,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _BatchFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _BatchFilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : const Color(0xFFFBF8F1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : const Color(0xFFEADCC5),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : InvColors.textDark,
          ),
        ),
      ),
    );
  }
}
