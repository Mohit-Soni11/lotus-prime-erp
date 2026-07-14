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

  @override
  Widget build(BuildContext context) {
    final title = _inventoryGradeTitle(
      widget.ui.category,
      widget.grade.gradeLabel,
    );
    final subtitle = _inventoryGradeSubtitle(
      widget.ui.category,
      widget.grade.gradeLabel,
      widget.grade.availableUnits,
      widget.grade.totalUnits,
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
                        label: 'Net Weight',
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
                        label: 'Actual Fine',
                        value: '${_weight(widget.grade.actualFine)} g',
                        icon: Icons.verified_rounded,
                        accent: const Color(0xFF10B981),
                        surface: const Color(0xFFEAFBF5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradeMetricTile(
                        label: 'Valuation Fine',
                        value: '${_weight(widget.grade.valuationFine)} g',
                        icon: Icons.trending_up_rounded,
                        accent: InvColors.brandGold,
                        surface: const Color(0xFFFFF7DF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7EF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEADCC5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: widget.ui.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Stock Value',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: InvColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _money(widget.grade.stockValue),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: InvColors.textDark,
                        ),
                      ),
                    ],
                  ),
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

  String _money(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 0,
    ).format(value);
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
