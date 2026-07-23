part of '../inventory_screen.dart';

class _InventoryGradeSummaryCard extends StatefulWidget {
  final _InventoryGradeSummary grade;
  final StockMetalUiData ui;
  final bool selected;
  final VoidCallback onTap;

  const _InventoryGradeSummaryCard({
    required this.grade,
    required this.ui,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InventoryGradeSummaryCard> createState() =>
      _InventoryGradeSummaryCardState();
}

class _InventoryGradeSummaryCardState
    extends State<_InventoryGradeSummaryCard> {
  bool _hovered = false;
  bool _showInformation = false;

  @override
  Widget build(BuildContext context) {
    final title = _inventoryGradeTitle(
      widget.ui.category,
      widget.grade.gradeLabel,
    );
    final subtitle = _inventoryGradeSubtitle(
      widget.ui.category,
      widget.grade.gradeLabel,
      widget.grade.availablePieces,
      widget.grade.totalPieces,
      widget.grade.companyCount,
      widget.grade.purityGroupCount,
      widget.grade.availableQuantityLabel,
    );
    final borderColor = widget.selected
        ? widget.ui.accent
        : _hovered
            ? widget.ui.accent.withValues(alpha: 0.55)
            : InvColors.cardBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: widget.ui.accent.withValues(
                    alpha: widget.selected ? 0.16 : 0.08,
                  ),
                  blurRadius: widget.selected ? 24 : 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: widget.ui.gradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: widget.ui.accent.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.ui.icon,
                        color: widget.ui.textOnGradient,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: InvColors.textDark,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? widget.ui.accent
                            : widget.ui.softTint.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.selected
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color:
                            widget.selected ? Colors.white : widget.ui.accent,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _GradeMetricTile(
                        label: 'Gross Weight',
                        value: '${_weight(widget.grade.grossWeight)} g',
                        icon: Icons.monitor_weight_outlined,
                        accent: widget.ui.accent,
                        surface: widget.ui.softSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradeMetricTile(
                        label: 'Available Weight',
                        value: '${_weight(widget.grade.netWeight)} g',
                        icon: Icons.scale_rounded,
                        accent: const Color(0xFF0F766E),
                        surface: const Color(0xFFEFFCF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _GradeMetricTile(
                        label: 'Total Weight',
                        value:
                            '${_weight(widget.grade.netWeight + widget.grade.soldWeight)} g',
                        icon: Icons.inventory_2_rounded,
                        accent: widget.ui.accent,
                        surface: widget.ui.softSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradeMetricTile(
                        label: 'Sold Weight',
                        value: '${_weight(widget.grade.soldWeight)} g',
                        icon: Icons.point_of_sale_rounded,
                        accent: InvColors.danger,
                        surface: InvColors.dangerBg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _GradeAvailabilityStrip(
                  availablePieces: widget.grade.availablePieces,
                  soldPieces: widget.grade.soldPieces,
                  totalSets: widget.grade.totalSets,
                  availableSets: widget.grade.availableSets,
                  unitLabel: widget.grade.quantityUnitLabel,
                  availableQuantityLabel: widget.grade.availableQuantityLabel,
                  soldQuantityLabel: widget.grade.soldQuantityLabel,
                  unitBalanceLabel: widget.grade.unitBalanceLabel,
                  statusText: widget.grade.statusLabel,
                  accent: widget.ui.accent,
                ),
                const SizedBox(height: 12),
                _GradeInformationToggle(
                  expanded: _showInformation,
                  accent: widget.ui.accent,
                  onTap: () =>
                      setState(() => _showInformation = !_showInformation),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _showInformation
                      ? Padding(
                          key: const ValueKey('grade_information'),
                          padding: const EdgeInsets.only(top: 12),
                          child: _GradeAvailableInformationPanel(
                            grade: widget.grade,
                            accent: widget.ui.accent,
                            weightFormatter: _weight,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _weight(double value) {
    return NumberFormat('##,##0.000', 'en_IN').format(value);
  }
}

class _GradeInformationToggle extends StatelessWidget {
  final bool expanded;
  final Color accent;
  final VoidCallback onTap;

  const _GradeInformationToggle({
    required this.expanded,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: expanded ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expanded
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 8),
              Text(
                expanded ? 'Hide Information' : 'Show Information',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeAvailableInformationPanel extends StatelessWidget {
  final _InventoryGradeSummary grade;
  final Color accent;
  final String Function(double value) weightFormatter;

  const _GradeAvailableInformationPanel({
    required this.grade,
    required this.accent,
    required this.weightFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (grade.availableInfo.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7EF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEADCC5)),
        ),
        child: Text(
          'No available item detail is recorded in this grade.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: InvColors.textMuted,
          ),
        ),
      );
    }

    final visibleItems = grade.availableInfo.take(4).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, color: accent, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Available Item Information',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
              ),
              Text(
                '${grade.availableInfo.length} lines',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: InvColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in visibleItems) ...[
            _GradeAvailableInformationRow(
              item: item,
              accent: accent,
              weightFormatter: weightFormatter,
            ),
            if (item != visibleItems.last) const SizedBox(height: 8),
          ],
          if (grade.availableInfo.length > visibleItems.length) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${grade.availableInfo.length - visibleItems.length} more available lines inside this grade',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeAvailableInformationRow extends StatelessWidget {
  final _InventoryGradeAvailableInfo item;
  final Color accent;
  final String Function(double value) weightFormatter;

  const _GradeAvailableInformationRow({
    required this.item,
    required this.accent,
    required this.weightFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.itemType} - ${item.segment}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: InvColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.pieces} pcs',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: InvColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item.itemName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AvailableInfoMetric(
                  label: 'Gross',
                  value: '${weightFormatter(item.grossWeight)} g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AvailableInfoMetric(
                  label: 'Available',
                  value: '${weightFormatter(item.netWeight)} g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailableInfoMetric extends StatelessWidget {
  final String label;
  final String value;

  const _AvailableInfoMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
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
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeAvailabilityStrip extends StatelessWidget {
  final int availablePieces;
  final int soldPieces;
  final int totalSets;
  final int availableSets;
  final String unitLabel;
  final String availableQuantityLabel;
  final String soldQuantityLabel;
  final String unitBalanceLabel;
  final String statusText;
  final Color accent;

  const _GradeAvailabilityStrip({
    required this.availablePieces,
    required this.soldPieces,
    required this.totalSets,
    required this.availableSets,
    required this.unitLabel,
    required this.availableQuantityLabel,
    required this.soldQuantityLabel,
    required this.unitBalanceLabel,
    required this.statusText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = statusText == 'Sold Out';
    final isPartiallySold = statusText == 'Partially Sold';
    final statusColor = isSoldOut
        ? InvColors.danger
        : isPartiallySold
            ? const Color(0xFFF59E0B)
            : InvColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: _AvailabilityText(
              label: 'Available Qty',
              value: availableQuantityLabel,
              color: InvColors.success,
            ),
          ),
          Container(width: 1, height: 30, color: const Color(0xFFEADCC5)),
          Expanded(
            child: _AvailabilityText(
              label: 'Sold Qty',
              value: soldQuantityLabel,
              color: soldPieces > 0 ? InvColors.danger : InvColors.textMuted,
            ),
          ),
          Container(width: 1, height: 30, color: const Color(0xFFEADCC5)),
          Expanded(
            child: _AvailabilityText(
              label: 'Unit Balance',
              value: unitBalanceLabel,
              color: totalSets > 0 || unitLabel != 'pcs'
                  ? accent
                  : InvColors.textDark,
            ),
          ),
          Container(width: 1, height: 30, color: const Color(0xFFEADCC5)),
          Expanded(
            child: _AvailabilityText(
              label: 'Status',
              value: statusText,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityText extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AvailabilityText({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color surface;

  const _GradeMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
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
                    letterSpacing: 0.4,
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
          ),
        ],
      ),
    );
  }
}
