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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: InvColors.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
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
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _batchSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _BatchMetric(
                label: 'Items',
                value: '${batch.availableItems}/${batch.totalItems}',
                accent: ui.accent,
              ),
              _BatchMetric(
                label: 'Gross Weight',
                value: '${_weight(batch.grossWeight)} g',
                accent: ui.accent,
              ),
              _BatchMetric(
                label: 'Actual Fine',
                value: '${_weight(batch.actualFine)} g',
                accent: const Color(0xFF10B981),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ui.softTint.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.open_in_full_rounded,
                  color: ui.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _batchSubtitle() {
    final parts = [
      batch.supplierName.isEmpty ? 'Supplier not linked' : batch.supplierName,
      if (batch.supplierInvoiceNo.isNotEmpty)
        'Invoice ${batch.supplierInvoiceNo}',
      if (batch.createdAt > 0) _date(batch.createdAt),
    ];
    return parts.join(' - ');
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
    final available = unit.status.toLowerCase() == 'available';
    final statusColor = available ? InvColors.success : InvColors.danger;
    final statusBg = available ? InvColors.successBg : InvColors.dangerBg;

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
                  unit.status.isEmpty ? 'Available' : unit.status,
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
              _UnitMetric(
                  label: 'HUID',
                  value: unit.huid.isEmpty ? 'No HUID' : unit.huid),
              _UnitMetric(
                  label: 'Gross', value: '${_weight(unit.grossWeight)} g'),
              _UnitMetric(label: 'Net', value: '${_weight(unit.netWeight)} g'),
              _UnitMetric(
                  label: 'Purity', value: '${_percent(unit.purityPercent)}%'),
              _UnitMetric(
                  label: 'Wastage', value: '${_percent(unit.wastagePercent)}%'),
              _UnitMetric(
                  label: 'Actual Fine', value: '${_weight(unit.actualFine)} g'),
              _UnitMetric(
                  label: 'Wastage Fine',
                  value: '${_weight(unit.wastageFine)} g'),
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
      unit.itemType,
      unit.segment,
      unit.unitCode,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'Stock unit' : parts.join(' - ');
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }
}

class _BatchMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _BatchMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
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
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
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
