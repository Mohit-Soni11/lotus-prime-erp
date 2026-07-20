import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockAlertHeader extends StatelessWidget {
  final LowStockAlertSummary summary;
  final List<LowStockStockCard> metalCards;

  const LowStockAlertHeader({
    super.key,
    required this.summary,
    required this.metalCards,
  });

  @override
  Widget build(BuildContext context) {
    final healthColor = summary.stockoutGroups > 0 || summary.criticalGroups > 0
        ? InvColors.danger
        : summary.lowGroups > 0
            ? InvColors.brandGold
            : InvColors.success;
    final healthLabel = summary.stockoutGroups > 0
        ? 'Immediate reorder required'
        : summary.criticalGroups > 0
            ? 'Critical stock watch'
            : summary.lowGroups > 0
                ? 'Low stock watch'
                : 'Stock levels stable';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: InvColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InvColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: InvColors.shadowMedium,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 940;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: InvColors.brandGoldLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: InvColors.brandGold.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.crisis_alert_rounded,
                      color: InvColors.brandGold,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Low Stock Control Center',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: InvColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Metal-wise shortage alerts from your live inventory rules.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: InvColors.textBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LowStockStatusPill(label: healthLabel, color: healthColor),
                ],
              ),
              const SizedBox(height: 18),
              if (metalCards.isEmpty)
                const _HealthyOverview()
              else
                _MetalAlertOverview(
                  cards: metalCards,
                  compact: compact,
                  criticalCount: summary.criticalGroups,
                  stockoutCount: summary.stockoutGroups,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HealthyOverview extends StatelessWidget {
  const _HealthyOverview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InvColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: InvColors.success.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: InvColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: InvColors.success,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All Stock Alerts Clear', style: InvStyles.itemName),
                const SizedBox(height: 3),
                Text(
                  'No metal has crossed its low-stock rule right now.',
                  style: InvStyles.itemSku,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalAlertOverview extends StatelessWidget {
  final List<LowStockStockCard> cards;
  final bool compact;
  final int criticalCount;
  final int stockoutCount;

  const _MetalAlertOverview({
    required this.cards,
    required this.compact,
    required this.criticalCount,
    required this.stockoutCount,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? double.infinity : 260.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _MetalAlertTile(card: card),
              ),
          ],
        ),
        if (criticalCount > 0 || stockoutCount > 0) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (stockoutCount > 0)
                _AlertCountPill(
                  label: 'Stockout Items',
                  value: stockoutCount,
                  color: InvColors.danger,
                ),
              if (criticalCount > 0)
                _AlertCountPill(
                  label: 'Critical Items',
                  value: criticalCount,
                  color: const Color(0xFFDC2626),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MetalAlertTile extends StatelessWidget {
  final LowStockStockCard card;

  const _MetalAlertTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(StockCategory.fromLabel(card.metalType));
    final riskColor = lowStockRiskColor(card.riskLevel);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ui.softTint.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ui.accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: ui.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ui.icon, color: ui.textOnGradient, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${card.metalType} Alert',
                  style: InvStyles.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${card.availableUnits} available | ${card.soldUnits} sold',
                  style: InvStyles.itemSku,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          LowStockStatusPill(
            label: lowStockRiskLabel(card.riskLevel),
            color: riskColor,
          ),
        ],
      ),
    );
  }
}

class _AlertCountPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AlertCountPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
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
