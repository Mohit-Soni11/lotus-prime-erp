import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockSmartCard extends StatefulWidget {
  final LowStockStockCard card;
  final String actionLabel;
  final String? titleOverride;
  final String? subtitleOverride;
  final bool selected;
  final VoidCallback? onTap;

  const LowStockSmartCard({
    super.key,
    required this.card,
    required this.actionLabel,
    this.titleOverride,
    this.subtitleOverride,
    this.selected = false,
    this.onTap,
  });

  @override
  State<LowStockSmartCard> createState() => _LowStockSmartCardState();
}

class _LowStockSmartCardState extends State<LowStockSmartCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.fromLabel(widget.card.metalType));
    final riskColor = lowStockRiskColor(widget.card.riskLevel);
    final borderColor = widget.selected || _hovered
        ? ui.accent.withValues(alpha: 0.58)
        : ui.accent.withValues(alpha: 0.20);
    final shadowOpacity = widget.selected || _hovered ? 0.18 : 0.09;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: ui.accent.withValues(alpha: 0.08),
            highlightColor: ui.accent.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: ui.softSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: ui.accent.withValues(alpha: shadowOpacity),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CardVisual(ui: ui, card: widget.card),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.titleOverride ?? widget.card.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: InvColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitleOverride ?? widget.card.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                  color: InvColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LowStockStatusPill(
                          label: lowStockRiskLabel(widget.card.riskLevel),
                          color: riskColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Previous Pcs',
                            value: '${widget.card.totalUnits} pcs',
                            accent: ui.accent,
                            surface: ui.softTint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricTile(
                            label: 'Current Pcs',
                            value: '${widget.card.availableUnits} pcs',
                            accent: InvColors.success,
                            surface: InvColors.successBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Sold Pcs',
                            value: '${widget.card.soldUnits} pcs',
                            accent: InvColors.danger,
                            surface: InvColors.dangerBg,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricTile(
                            label: 'Add Stock',
                            value: '${widget.card.suggestedReorderUnits} pcs',
                            accent: riskColor,
                            surface: riskColor.withValues(alpha: 0.10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Current Weight',
                            value:
                                lowStockWeight(widget.card.availableNetWeight),
                            accent: ui.accent,
                            surface: ui.softTint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricTile(
                            label: 'Need Weight',
                            value: lowStockWeight(
                              widget.card.suggestedReorderNetWeight,
                            ),
                            accent: riskColor,
                            surface: riskColor.withValues(alpha: 0.10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? ui.accent
                            : ui.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: ui.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.actionLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: widget.selected ? Colors.white : ui.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: widget.selected ? Colors.white : ui.accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardVisual extends StatelessWidget {
  final StockMetalUiData ui;
  final LowStockStockCard card;

  const _CardVisual({required this.ui, required this.card});

  @override
  Widget build(BuildContext context) {
    final icon = switch (card.level) {
      LowStockCardLevel.metal => ui.icon,
      LowStockCardLevel.grade => Icons.auto_awesome_mosaic_rounded,
      LowStockCardLevel.itemGroup => Icons.category_rounded,
      _ => Icons.inventory_2_outlined,
    };
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: ui.gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: card.level == LowStockCardLevel.metal && ui.logoAsset != null
          ? Image.asset(
              ui.logoAsset!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                icon,
                color: ui.textOnGradient,
                size: 28,
              ),
            )
          : Icon(icon, color: ui.textOnGradient, size: 28),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final Color surface;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 16,
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
