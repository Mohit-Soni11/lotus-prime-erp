import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/stock_metal_ui.dart';

class SilverBatchOverviewCard extends StatelessWidget {
  final SilverStockController ctrl;

  const SilverBatchOverviewCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(ctrl.selectedMetal);
    final purity = ctrl.purityDisplay.trim().isEmpty
        ? 'Purity Not Set'
        : ctrl.purityDisplay.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: AddStockColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _accentLine(20, ui.accent, 1.0),
                        const SizedBox(height: 3),
                        _accentLine(13, ui.accent, 0.45),
                        const SizedBox(height: 3),
                        _accentLine(7, ui.accent, 0.18),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BATCH OVERVIEW',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AddStockColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ui.title} intake • ${ctrl.enteredRowCount} entered row${ctrl.enteredRowCount == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ctrl.gstEnabled
                                  ? AddStockColors.success
                                  : AddStockColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _GstStatusPill(
                isGst: ctrl.gstEnabled,
                accent: ui.accent,
                onTap: () => ctrl.toggleGst(!ctrl.gstEnabled),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            width: double.infinity,
            color: AddStockColors.cardBorder,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: ui.gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ui.accent.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(ui.icon, color: ui.textOnGradient, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(ui.title.toUpperCase(), ui.accent),
                    _pill(purity.toUpperCase(), AddStockColors.accentPricing),
                    _pill('BATCH 1', AddStockColors.textBody),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'PIECES',
                  value: '${ctrl.totalQuantity}',
                  icon: Icons.tag_rounded,
                  iconColor: AddStockColors.accentInventory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'GROSS WT',
                  value: '${ctrl.totalGrossWeight.toStringAsFixed(3)} g',
                  icon: AddStockIcons.weight,
                  iconColor: ui.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'NET WT',
                  value: '${ctrl.totalNetWeight.toStringAsFixed(3)} g',
                  icon: AddStockIcons.netWeight,
                  iconColor: AddStockColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accentLine(double width, Color color, double opacity) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

class _GstStatusPill extends StatelessWidget {
  final bool isGst;
  final Color accent;
  final VoidCallback onTap;

  const _GstStatusPill({
    required this.isGst,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isGst ? AddStockColors.success : accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activeColor.withOpacity(0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isGst ? 'GST BILL' : 'NORMAL',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AddStockColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AddStockColors.textDark,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
