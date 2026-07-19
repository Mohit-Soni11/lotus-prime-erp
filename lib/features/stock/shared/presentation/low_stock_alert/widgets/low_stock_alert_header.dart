import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockAlertHeader extends StatelessWidget {
  final LowStockAlertSummary summary;

  const LowStockAlertHeader({super.key, required this.summary});

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
                          'Low Stock Command Center',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: InvColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reorder risk, stockout prevention and supplier readiness in one control panel.',
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
              GridView.count(
                crossAxisCount: compact ? 2 : 6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: compact ? 2.55 : 2.05,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _HeroMetric(
                    label: 'Watched Groups',
                    value: '${summary.watchedGroups}',
                  ),
                  _HeroMetric(
                    label: 'Low Alerts',
                    value: '${summary.lowGroups}',
                  ),
                  _HeroMetric(
                    label: 'Critical',
                    value: '${summary.criticalGroups}',
                  ),
                  _HeroMetric(
                    label: 'Stockout',
                    value: '${summary.stockoutGroups}',
                  ),
                  _HeroMetric(
                    label: 'Available',
                    value: '${summary.availableUnits} pcs',
                  ),
                  _HeroMetric(
                    label: 'Net Weight',
                    value: lowStockWeight(summary.availableNetWeight),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: InvColors.bodyBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: lowStockHeroLabel(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
