import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockRuleSetupCard extends StatefulWidget {
  final LowStockStockCard card;
  final String actionLabel;
  final VoidCallback onTap;

  const LowStockRuleSetupCard({
    super.key,
    required this.card,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  State<LowStockRuleSetupCard> createState() => _LowStockRuleSetupCardState();
}

class _LowStockRuleSetupCardState extends State<LowStockRuleSetupCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final ui = stockMetalUiFor(StockCategory.fromLabel(card.metalType));
    final unit = _unitName(card.unitLabel, plural: false);
    final units = _unitName(card.unitLabel, plural: true);
    final scope = _scopeLabel(card);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.01 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: ui.accent.withValues(alpha: 0.08),
            highlightColor: ui.accent.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hovered
                      ? ui.accent.withValues(alpha: 0.44)
                      : InvColors.cardBorder,
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.045),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _RuleCardIcon(ui: ui, card: card),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title,
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
                                scope,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: InvColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LowStockStatusPill(
                          label: card.ruleMode.toUpperCase(),
                          color: ui.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _RuleMetricGrid(
                      metrics: [
                        _RuleMetric(
                          label: 'Total $units',
                          value: _quantity(card.totalUnits, unit),
                          icon: Icons.inventory_2_rounded,
                          color: InvColors.brandGold,
                        ),
                        _RuleMetric(
                          label: 'Available $units',
                          value: _quantity(card.availableUnits, unit),
                          icon: Icons.check_circle_rounded,
                          color: InvColors.success,
                        ),
                        _RuleMetric(
                          label: 'Sold $units',
                          value: _quantity(card.soldUnits, unit),
                          icon: Icons.point_of_sale_rounded,
                          color: InvColors.danger,
                        ),
                        _RuleMetric(
                          label: 'Current Weight',
                          value: lowStockWeight(card.availableNetWeight),
                          icon: Icons.scale_rounded,
                          color: InvColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: ui.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: ui.accent.withValues(alpha: 0.22),
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
                              color: ui.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: ui.accent,
                            size: 18,
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

  String _scopeLabel(LowStockStockCard card) {
    switch (card.level) {
      case LowStockCardLevel.metal:
        return card.metalType.trim().toLowerCase() == 'silver'
            ? 'Select item type to set alert rule'
            : 'Select purity grade to set alert rule';
      case LowStockCardLevel.grade:
        return '${card.metalType} grade. Open item types next.';
      case LowStockCardLevel.itemGroup:
        return '${card.metalType} item type. Configure levels here.';
      default:
        return '${card.metalType} / ${card.gradeLabel}';
    }
  }
}

class _RuleCardIcon extends StatelessWidget {
  final StockMetalUiData ui;
  final LowStockStockCard card;

  const _RuleCardIcon({required this.ui, required this.card});

  @override
  Widget build(BuildContext context) {
    final icon = switch (card.level) {
      LowStockCardLevel.metal => ui.icon,
      LowStockCardLevel.grade => Icons.auto_awesome_mosaic_rounded,
      LowStockCardLevel.itemGroup => Icons.category_rounded,
      _ => Icons.inventory_2_outlined,
    };
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: ui.gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: card.level == LowStockCardLevel.metal && ui.logoAsset != null
          ? Image.asset(
              ui.logoAsset!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                icon,
                color: ui.textOnGradient,
                size: 26,
              ),
            )
          : Icon(icon, color: ui.textOnGradient, size: 26),
    );
  }
}

class _RuleMetricGrid extends StatelessWidget {
  final List<_RuleMetric> metrics;

  const _RuleMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _RuleMetricTile(metric: metrics[0])),
            const SizedBox(width: 10),
            Expanded(child: _RuleMetricTile(metric: metrics[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _RuleMetricTile(metric: metrics[2])),
            const SizedBox(width: 10),
            Expanded(child: _RuleMetricTile(metric: metrics[3])),
          ],
        ),
      ],
    );
  }
}

class _RuleMetricTile extends StatelessWidget {
  final _RuleMetric metric;

  const _RuleMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: metric.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: metric.color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    style: GoogleFonts.manrope(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: InvColors.textDark,
                    ),
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

class _RuleMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RuleMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

String _quantity(int value, String unit) => '$value $unit';

String _unitName(String raw, {required bool plural}) {
  final unit = raw.trim().toLowerCase();
  switch (unit) {
    case 'pair':
      return plural ? 'pairs' : 'pair';
    case 'set':
      return plural ? 'sets' : 'set';
    case 'packet':
      return plural ? 'packets' : 'packet';
    case 'bulk':
      return 'bulk';
    case 'item':
      return plural ? 'items' : 'item';
    default:
      return 'pcs';
  }
}
