import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

class SalesReportMetalPerformanceCard extends StatelessWidget {
  final SalesReportMetalSummary metal;
  final String periodLabel;
  final bool selected;
  final VoidCallback onTap;

  const SalesReportMetalPerformanceCard({
    super.key,
    required this.metal,
    required this.periodLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(_categoryFor(metal.metalType));
    final title = '${ui.title} Sales';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: ui.softSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? ui.accent.withValues(alpha: 0.60)
                  : ui.accent.withValues(alpha: 0.24),
              width: selected ? 1.6 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: ui.accent.withValues(alpha: selected ? 0.14 : 0.08),
                blurRadius: selected ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MetalMark(ui: ui),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SalesReportStyles.pageTitle.copyWith(
                              color: SalesReportColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$periodLabel - ${_subtitleFor(ui.category)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SalesReportStyles.body.copyWith(
                              color: SalesReportColors.textPrimary,
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _CardMetricTile(
                        label: 'Sales Value',
                        value: salesReportMoney(metal.salesAmount),
                        accent: ui.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CardMetricTile(
                        label: 'Net Weight Sold',
                        value: salesReportWeight(metal.netWeight),
                        accent: ui.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _OpenLedgerButton(
                  label: selected
                      ? '${ui.title} Ledger Open'
                      : 'View ${ui.title} Ledger',
                  accent: ui.accent,
                  selected: selected,
                ),
              ],
            ),
          ),
        ),
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

class _MetalMark extends StatelessWidget {
  final StockMetalUiData ui;

  const _MetalMark({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: ui.gradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ui.accent.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ui.logoAsset == null
          ? Icon(ui.icon, color: ui.textOnGradient, size: 26)
          : Image.asset(
              ui.logoAsset!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                ui.icon,
                color: ui.textOnGradient,
                size: 26,
              ),
            ),
    );
  }
}

class _CardMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _CardMetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesReportStyles.body.copyWith(
              color: SalesReportColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: SalesReportStyles.pageTitle.copyWith(
                color: SalesReportColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenLedgerButton extends StatelessWidget {
  final String label;
  final Color accent;
  final bool selected;

  const _OpenLedgerButton({
    required this.label,
    required this.accent,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : SalesReportColors.textPrimary;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: selected ? accent : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: SalesReportStyles.body.copyWith(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 18, color: foreground),
        ],
      ),
    );
  }
}
