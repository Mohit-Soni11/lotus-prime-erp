import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

String lowStockWeight(double value) => '${value.toStringAsFixed(3)} g';

Color lowStockRiskColor(String riskLevel) {
  switch (riskLevel) {
    case LowStockRiskLevel.stockout:
      return InvColors.danger;
    case LowStockRiskLevel.critical:
      return const Color(0xFFDC2626);
    case LowStockRiskLevel.low:
      return InvColors.brandGold;
    default:
      return InvColors.success;
  }
}

String lowStockRiskLabel(String riskLevel) {
  switch (riskLevel) {
    case LowStockRiskLevel.stockout:
      return 'STOCKOUT';
    case LowStockRiskLevel.critical:
      return 'CRITICAL';
    case LowStockRiskLevel.low:
      return 'LOW';
    default:
      return 'STABLE';
  }
}

class LowStockPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const LowStockPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: InvStyles.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class LowStockSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const LowStockSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: InvColors.brandGoldLight,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: InvColors.brandGold.withValues(alpha: 0.24),
            ),
          ),
          child: Icon(icon, color: InvColors.brandGold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: InvStyles.sectionTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 2),
              Text(subtitle, style: InvStyles.cardNote),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class LowStockStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const LowStockStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: InvStyles.statusBadgeText(color),
      ),
    );
  }
}

class LowStockMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const LowStockMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: InvStyles.cardLabel),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: InvStyles.cardMediumNumber.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LowStockEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const LowStockEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.notification_important_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: InvColors.textHint, size: 36),
          const SizedBox(height: 10),
          Text(title, style: InvStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(subtitle,
              style: InvStyles.cardNote, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

TextStyle lowStockHeroLabel() {
  return GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: InvColors.textMuted,
  );
}
