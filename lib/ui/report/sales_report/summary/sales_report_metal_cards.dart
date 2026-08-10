import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'package:lotus_erp/features/stock/shared/presentation/inventory/metal_hub/inventory_metal_summary_card.dart';
import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

class SalesReportMetalCards extends StatelessWidget {
  final List<SalesReportMetalSummary> metals;
  final String selectedMetal;
  final String periodLabel;
  final ValueChanged<String> onMetalSelected;

  const SalesReportMetalCards({
    super.key,
    required this.metals,
    required this.selectedMetal,
    required this.periodLabel,
    required this.onMetalSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (metals.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: SalesReportStyles.panel(),
        child: Row(
          children: [
            const Icon(
              Icons.point_of_sale_rounded,
              color: SalesReportColors.brandGold,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Metal sales cards will appear once sales are available for the selected filter.',
                style: SalesReportStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SalesReportColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final width = constraints.maxWidth >= 960
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metal in metals)
              SizedBox(
                width: width,
                child: _SalesMetalInventoryCard(
                  metal: metal,
                  periodLabel: periodLabel,
                  selected: selectedMetal.toUpperCase() ==
                      metal.metalType.toUpperCase(),
                  onTap: () => onMetalSelected(metal.metalType),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SalesMetalInventoryCard extends StatelessWidget {
  final SalesReportMetalSummary metal;
  final String periodLabel;
  final bool selected;
  final VoidCallback onTap;

  const _SalesMetalInventoryCard({
    required this.metal,
    required this.periodLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(_categoryFor(metal.metalType));
    return InventoryMetalSummaryCard(
      title: '${ui.title} Sales Report',
      subtitle: '$periodLabel - ${_subtitleFor(ui.category)}',
      primaryLabel: 'Sales Value',
      primaryValue: salesReportMoney(metal.salesAmount),
      weightLabel: 'Net Weight Sold',
      weightValue: salesReportWeight(metal.netWeight),
      actionLabel:
          selected ? '${ui.title} Sales Open' : 'Open ${ui.title} Sales',
      icon: ui.icon,
      logoAsset: ui.logoAsset,
      accent: ui.accent,
      surface: ui.softSurface,
      tint: ui.softTint,
      gradient: ui.gradient,
      textOnGradient: ui.textOnGradient,
      selected: selected,
      onTap: onTap,
    );
  }

  StockCategory _categoryFor(String metal) {
    switch (metal.toLowerCase()) {
      case 'gold':
        return StockCategory.gold;
      case 'silver':
        return StockCategory.silver;
      case 'platinum':
        return StockCategory.platinum;
      case 'diamond':
        return StockCategory.diamond;
      default:
        return StockCategory.other;
    }
  }

  String _subtitleFor(StockCategory category) {
    switch (category) {
      case StockCategory.gold:
        return 'Gold invoices, HUID movement, making and sales tracking';
      case StockCategory.silver:
        return 'Silver item sales, weight flow, pieces and counter movement';
      case StockCategory.diamond:
        return 'Diamond sales value, item ledger and premium stock audit';
      case StockCategory.platinum:
        return 'Platinum sales value, purity and high-value item audit';
      case StockCategory.antique:
      case StockCategory.other:
        return 'Metal-wise sales value, quantity and item movement audit';
    }
  }
}

class SalesReportMetalDetailPanel extends StatelessWidget {
  final SalesReportMetalSummary metal;
  final String periodLabel;
  final double recordedGstAmount;
  final double projectedGstAmount;
  final VoidCallback onBackToCards;

  const SalesReportMetalDetailPanel({
    super.key,
    required this.metal,
    required this.periodLabel,
    required this.recordedGstAmount,
    required this.projectedGstAmount,
    required this.onBackToCards,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(_categoryFor(metal.metalType));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ui.softSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ui.accent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: ui.gradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.antiAlias,
                child: ui.logoAsset == null
                    ? Icon(ui.icon, color: ui.textOnGradient, size: 24)
                    : Image.asset(
                        ui.logoAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          ui.icon,
                          color: ui.textOnGradient,
                          size: 24,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ui.title} Sales Ledger',
                      style: SalesReportStyles.pageTitle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$periodLabel sales detail filtered for ${ui.title}.',
                      style: SalesReportStyles.body,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onBackToCards,
                icon: const Icon(Icons.dashboard_customize_rounded, size: 17),
                label: const Text('All Metal Cards'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1200
                  ? 6
                  : constraints.maxWidth >= 900
                      ? 3
                      : 2;
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final metrics = [
                _MetalMetric('Invoices', '${metal.invoiceCount}',
                    Icons.receipt_long_rounded),
                _MetalMetric('Pieces', '${metal.pieces}',
                    Icons.confirmation_number_rounded),
                _MetalMetric('Net Weight', salesReportWeight(metal.netWeight),
                    Icons.monitor_weight_rounded),
                _MetalMetric('Sale Amount', salesReportMoney(metal.salesAmount),
                    Icons.point_of_sale_rounded),
                _MetalMetric('GST Total', salesReportMoney(recordedGstAmount),
                    Icons.verified_rounded),
                _MetalMetric(
                    'Projected GST',
                    salesReportMoney(projectedGstAmount),
                    Icons.calculate_rounded),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: width,
                      child: _MetricBlock(metric: metric, accent: ui.accent),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  StockCategory _categoryFor(String metal) {
    switch (metal.toLowerCase()) {
      case 'gold':
        return StockCategory.gold;
      case 'silver':
        return StockCategory.silver;
      case 'platinum':
        return StockCategory.platinum;
      case 'diamond':
        return StockCategory.diamond;
      default:
        return StockCategory.other;
    }
  }
}

class _MetalMetric {
  final String label;
  final String value;
  final IconData icon;

  const _MetalMetric(this.label, this.value, this.icon);
}

class _MetricBlock extends StatelessWidget {
  final _MetalMetric metric;
  final Color accent;

  const _MetricBlock({required this.metric, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesReportStyles.body.copyWith(
                    fontSize: 11,
                    color: SalesReportColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    style: SalesReportStyles.pageTitle.copyWith(fontSize: 17),
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
