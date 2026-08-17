import 'package:flutter/material.dart';

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_metric_card.dart';
import 'gst_report_panel.dart';

class GstDashboardView extends StatelessWidget {
  const GstDashboardView({
    super.key,
    required this.snapshot,
  });

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final dashboard = snapshot.dashboard;
    final criticalCount = snapshot.auditFindings
        .where((item) => item.severity == GstAuditSeverity.critical)
        .length;
    final warningCount = snapshot.auditFindings
        .where((item) => item.severity == GstAuditSeverity.warning)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GstReportPanel(
          title: 'GST Dashboard',
          subtitle: GstReportFormatters.periodLabel(snapshot.period),
          icon: GstReportIcons.dashboard,
          child: _ShopIdentityStrip(identity: snapshot.identity),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 1200
                    ? (constraints.maxWidth - 42) / 4
                    : constraints.maxWidth >= 760
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'Total Invoices',
                    value: GstReportFormatters.count(dashboard.gstInvoiceCount),
                    subtitle:
                        '${dashboard.exclusive.invoiceCount} exclusive / ${dashboard.inclusive.invoiceCount} inclusive',
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'Total Value',
                    value: GstReportFormatters.money(
                      dashboard.gstInvoiceValue,
                    ),
                    subtitle: 'Exclusive + inclusive invoices',
                    icon: Icons.payments_rounded,
                    accentColor: GstReportColors.taxGreen,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'CGST',
                    value: GstReportFormatters.money(dashboard.cgstAmount),
                    icon: Icons.south_west_rounded,
                    accentColor: GstReportColors.success,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'SGST',
                    value: GstReportFormatters.money(dashboard.sgstAmount),
                    icon: Icons.south_east_rounded,
                    accentColor: GstReportColors.success,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'IGST',
                    value: GstReportFormatters.money(dashboard.igstAmount),
                    icon: Icons.sync_alt_rounded,
                    accentColor: GstReportColors.warning,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'Output GST Liability',
                    value: GstReportFormatters.money(dashboard.totalGst),
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: GstReportColors.danger,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'Review Sales',
                    value: GstReportFormatters.money(
                      dashboard.nonGstSalesEstimate,
                    ),
                    subtitle: dashboard.nonGstInvoiceCount == 0
                        ? 'No review bills'
                        : '${dashboard.nonGstInvoiceCount} bills need review',
                    icon: Icons.request_quote_outlined,
                    accentColor: GstReportColors.textMuted,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'Mismatch Alerts',
                    value: '$criticalCount critical / $warningCount warning',
                    subtitle: 'Open Audit tab before filing',
                    icon: Icons.error_outline_rounded,
                    accentColor: criticalCount > 0
                        ? GstReportColors.danger
                        : GstReportColors.success,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _PricingBreakdownGrid(dashboard: dashboard),
        const SizedBox(height: 16),
        _RateSummaryPanel(rows: snapshot.rateSummary),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _PricingBreakdownGrid extends StatelessWidget {
  const _PricingBreakdownGrid({required this.dashboard});

  final GstReportDashboardSummary dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 980
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: width,
              child: _PricingModeSummaryCard(
                title: 'GST Exclusive Invoice Summary',
                subtitle: 'GST charged separately over taxable value',
                icon: Icons.add_card_rounded,
                accent: GstReportColors.information,
                summary: dashboard.exclusive,
              ),
            ),
            SizedBox(
              width: width,
              child: _PricingModeSummaryCard(
                title: 'GST Inclusive Invoice Summary',
                subtitle: 'GST reverse-calculated from customer final price',
                icon: Icons.price_check_rounded,
                accent: GstReportColors.success,
                summary: dashboard.inclusive,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PricingModeSummaryCard extends StatelessWidget {
  const _PricingModeSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.summary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final GstPricingModeSummary summary;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Invoices', GstReportFormatters.count(summary.invoiceCount)),
      ('Total Value', GstReportFormatters.money(summary.invoiceValue)),
      ('Taxable Value', GstReportFormatters.money(summary.taxableValue)),
      ('CGST', GstReportFormatters.money(summary.cgstAmount)),
      ('SGST', GstReportFormatters.money(summary.sgstAmount)),
      ('IGST', GstReportFormatters.money(summary.igstAmount)),
      ('Output GST', GstReportFormatters.money(summary.outputGst)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GstReportStyles.sectionTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GstReportStyles.body.copyWith(
                        color: GstReportColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final row in rows)
                _SummaryChip(
                  label: row.$1,
                  value: row.$2,
                  accent: accent,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopIdentityStrip extends StatelessWidget {
  const _ShopIdentityStrip({required this.identity});

  final GstReportShopIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _IdentityChip(label: 'Shop', value: identity.shopName),
        _IdentityChip(
          label: 'GSTIN',
          value: identity.gstin.isEmpty ? 'Not configured' : identity.gstin,
        ),
        _IdentityChip(
          label: 'State Code',
          value: identity.stateCode.isEmpty ? 'Pending' : identity.stateCode,
        ),
        _IdentityChip(
          label: 'State',
          value: identity.stateName.isEmpty ? 'Pending' : identity.stateName,
        ),
      ],
    );
  }
}

class _IdentityChip extends StatelessWidget {
  const _IdentityChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GstReportColors.bodySubtle,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateSummaryPanel extends StatelessWidget {
  const _RateSummaryPanel({required this.rows});

  final List<GstRateSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Tax Rate Wise Sales',
      subtitle: 'Auto grouped from HSN register rows',
      icon: Icons.percent_rounded,
      child: rows.isEmpty
          ? const GstReportEmptyState(message: 'No tax-rate summary found.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 26,
                headingRowColor: WidgetStateProperty.all(
                  GstReportColors.bodySubtle,
                ),
                columns: const [
                  DataColumn(label: Text('Rate')),
                  DataColumn(label: Text('Invoices')),
                  DataColumn(label: Text('Taxable')),
                  DataColumn(label: Text('CGST')),
                  DataColumn(label: Text('SGST')),
                  DataColumn(label: Text('IGST')),
                  DataColumn(label: Text('GST')),
                  DataColumn(label: Text('Invoice Value')),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [
                        DataCell(Text(GstReportFormatters.rate(row.rate))),
                        DataCell(Text(GstReportFormatters.count(
                          row.invoiceCount,
                        ))),
                        DataCell(Text(GstReportFormatters.money(
                          row.taxableAmount,
                        ))),
                        DataCell(Text(GstReportFormatters.money(
                          row.cgstAmount,
                        ))),
                        DataCell(Text(GstReportFormatters.money(
                          row.sgstAmount,
                        ))),
                        DataCell(Text(GstReportFormatters.money(
                          row.igstAmount,
                        ))),
                        DataCell(Text(GstReportFormatters.money(
                          row.gstAmount,
                        ))),
                        DataCell(Text(GstReportFormatters.money(
                          row.invoiceValue,
                        ))),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
