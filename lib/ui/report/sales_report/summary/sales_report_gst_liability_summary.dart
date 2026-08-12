import 'package:flutter/material.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import '../../../../theme/reports/sales_report/sales_report_theme.dart';
import '../sales_report_formatters.dart';

class SalesReportGstLiabilityPanel extends StatelessWidget {
  final SalesReportGstLiabilitySummary summary;
  final String periodLabel;

  const SalesReportGstLiabilityPanel({
    super.key,
    required this.summary,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SalesReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SalesReportColors.brandGold.withValues(alpha: 0.30),
        ),
        boxShadow: const [
          BoxShadow(
            color: SalesReportColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SalesReportColors.goldGradientStart
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SalesReportColors.brandGold.withValues(alpha: 0.30),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: SalesReportColors.brandGold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GST Liability Summary',
                      style: SalesReportStyles.pageTitle.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$periodLabel monthly GST decision summary',
                      style: SalesReportStyles.body,
                    ),
                  ],
                ),
              ),
              _InvoiceCountBadge(summary: summary),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1260
                  ? 4
                  : constraints.maxWidth >= 760
                      ? 2
                      : 1;
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final tiles = [
                _GstMetric(
                  label: 'GST Taxable Sales',
                  value: salesReportMoney(summary.gstTaxableAmount),
                  helper: '${summary.gstInvoiceCount} GST invoices',
                  icon: Icons.verified_rounded,
                  accent: SalesReportColors.onlineGreen,
                ),
                _GstMetric(
                  label: 'GST Collected',
                  value: salesReportMoney(summary.recordedGstAmount),
                  helper: 'Recorded in GST invoices',
                  icon: Icons.receipt_long_rounded,
                  accent: SalesReportColors.information,
                ),
                _GstMetric(
                  label: 'Non-GST Sales Base',
                  value: salesReportMoney(summary.nonGstSalesAmount),
                  helper: '${summary.nonGstInvoiceCount} non-GST invoices',
                  icon: Icons.layers_rounded,
                  accent: SalesReportColors.textMuted,
                ),
                _GstMetric(
                  label: 'Projected GST on Non-GST',
                  value: salesReportMoney(summary.projectedGstAmount),
                  helper: '3% planning value',
                  icon: Icons.calculate_rounded,
                  accent: SalesReportColors.warning,
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final tile in tiles)
                    SizedBox(
                      width: width,
                      child: _GstMetricTile(metric: tile),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _ExposureStrip(summary: summary),
        ],
      ),
    );
  }
}

class _InvoiceCountBadge extends StatelessWidget {
  final SalesReportGstLiabilitySummary summary;

  const _InvoiceCountBadge({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: SalesReportColors.bodySubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SalesReportColors.bodyBorder),
      ),
      child: Text(
        '${summary.invoiceCount} Sales ${summary.invoiceCount == 1 ? 'Invoice' : 'Invoices'}',
        style: SalesReportStyles.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: SalesReportColors.textPrimary,
        ),
      ),
    );
  }
}

class _GstMetric {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color accent;

  const _GstMetric({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.accent,
  });
}

class _GstMetricTile extends StatelessWidget {
  final _GstMetric metric;

  const _GstMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: metric.accent.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: metric.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: metric.accent, size: 22),
          const SizedBox(width: 12),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: SalesReportColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    style: SalesReportStyles.pageTitle.copyWith(fontSize: 19),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  metric.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SalesReportStyles.body.copyWith(
                    fontSize: 11.5,
                    color: SalesReportColors.textMuted,
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

class _ExposureStrip extends StatelessWidget {
  final SalesReportGstLiabilitySummary summary;

  const _ExposureStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SalesReportColors.shellBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.summarize_rounded,
            color: SalesReportColors.goldGradientStart,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recorded GST + projected GST on non-GST sales',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SalesReportStyles.body.copyWith(
                color: SalesReportColors.shellMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              salesReportMoney(summary.combinedGstExposure),
              style: SalesReportStyles.pageTitle.copyWith(
                color: SalesReportColors.shellTitle,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
