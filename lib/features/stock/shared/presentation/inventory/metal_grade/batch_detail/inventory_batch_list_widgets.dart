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
                        fontSize: 13.5,
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
                        fontSize: 13.5,
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
    final weightMetrics = _weightMetrics();
    final purityMetrics = _purityMetrics();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  unit.itemName.isEmpty
                      ? 'Unnamed Stock Item'
                      : _titleCase(unit.itemName),
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
                    fontSize: 12.5,
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
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: InvColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          _QuantityMetricStrip(
            accent: ui.accent,
            metrics: [
              _UnitMetricData('Unit', unit.displayUnitPlural),
              _UnitMetricData('Total Qty', unit.totalQuantityLabel),
              _UnitMetricData('Available', unit.availableQuantityLabel),
              _UnitMetricData('Sold', unit.soldQuantityLabel),
            ],
          ),
          if (unit.huidDisplayText.isNotEmpty) ...[
            const SizedBox(height: 10),
            _HuidMetric(value: unit.huidDisplayText, accent: ui.accent),
          ],
          const SizedBox(height: 12),
          _MetricSection(title: 'Weight', metrics: weightMetrics),
          if (purityMetrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MetricSection(title: 'Purity & Fine', metrics: purityMetrics),
          ],
        ],
      ),
    );
  }

  List<_UnitMetricData> _weightMetrics() {
    return [
      if (_hasWeightDifference(
          unit.displayTotalGrossWeight, unit.displayTotalNetWeight))
        _UnitMetricData(
          'Gross Weight',
          '${_weight(unit.displayTotalGrossWeight)} g',
        ),
      _UnitMetricData(
        'Total Weight',
        '${_weight(unit.displayTotalNetWeight)} g',
      ),
      if (unit.displayAvailableNetWeight > 0)
        _UnitMetricData(
          'Available Weight',
          '${_weight(unit.displayAvailableNetWeight)} g',
        ),
      if (unit.soldNetWeight > 0)
        _UnitMetricData('Sold Weight', '${_weight(unit.soldNetWeight)} g'),
      if (unit.hasScaleVariance)
        _UnitMetricData('Scale Variance', unit.scaleVarianceLabel),
    ];
  }

  List<_UnitMetricData> _purityMetrics() {
    return [
      if (unit.purityPercent > 0)
        _UnitMetricData('Base Purity', '${_percent(unit.purityPercent)}%'),
      if (unit.wastagePercent > 0)
        _UnitMetricData('Wastage', '${_percent(unit.wastagePercent)}%'),
      if (unit.totalPurityPercent > 0)
        _UnitMetricData(
            'Valuation Purity', '${_percent(unit.totalPurityPercent)}%'),
      if (unit.actualFine > 0)
        _UnitMetricData('Actual Fine', '${_weight(unit.actualFine)} g'),
      if (unit.valuationFine > 0)
        _UnitMetricData(
          'Valuation Fine',
          '${_weight(unit.valuationFine)} g',
        ),
    ];
  }

  String _itemSubtitle() {
    final parts = [
      unit.companyName,
      unit.itemType,
      unit.segment,
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

class _UnitMetricData {
  final String label;
  final String value;

  const _UnitMetricData(this.label, this.value);
}

class _QuantityMetricStrip extends StatelessWidget {
  final List<_UnitMetricData> metrics;
  final Color accent;

  const _QuantityMetricStrip({
    required this.metrics,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        if (compact) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: (constraints.maxWidth - 8) / 2,
                  child: _UnitMetric(
                    label: metric.label,
                    value: metric.value,
                    accent: accent,
                    highlighted: metric.label == 'Available',
                  ),
                ),
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              Expanded(
                child: _UnitMetric(
                  label: metrics[index].label,
                  value: metrics[index].value,
                  accent: accent,
                  highlighted: metrics[index].label == 'Available',
                ),
              ),
              if (index != metrics.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _MetricSection extends StatelessWidget {
  final String title;
  final List<_UnitMetricData> metrics;

  const _MetricSection({
    required this.title,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: InvColors.textDark,
          ),
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth >= 520
                ? (constraints.maxWidth - 16) / 3
                : (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: itemWidth,
                    child: _UnitMetric(
                      label: metric.label,
                      value: metric.value,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HuidMetric extends StatelessWidget {
  final String value;
  final Color accent;

  const _HuidMetric({
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HUID',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w900,
                color: InvColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
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
              fontSize: 12.5,
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
              fontSize: 15.5,
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
                fontSize: 12,
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
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _UnitMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;
  final bool highlighted;

  const _UnitMetric({
    required this.label,
    required this.value,
    this.accent,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeAccent = accent ?? InvColors.textDark;
    return Container(
      constraints: const BoxConstraints(minWidth: 98, minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color:
            highlighted ? activeAccent.withValues(alpha: 0.09) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? activeAccent.withValues(alpha: 0.24)
              : const Color(0xFFE7DAC5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: highlighted ? activeAccent : InvColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14.5,
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
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: accent,
          letterSpacing: 0,
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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
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
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : InvColors.textDark,
          ),
        ),
      ),
    );
  }
}
