import 'package:flutter/material.dart';

import '../../domain/gstr1_filing_models.dart';
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

  static const double _metricCardHeight = 140;

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
    final filing = Gstr1FilingSnapshot.fromReport(snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GstReportPanel(
          title: 'GST Dashboard',
          subtitle: GstReportFormatters.periodLabel(snapshot.period),
          icon: GstReportIcons.dashboard,
          child: _DashboardFilingContext(
            identity: snapshot.identity,
            documents: filing.documentSummary,
          ),
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
                    title: 'Total Invoice Count',
                    value: GstReportFormatters.count(dashboard.gstInvoiceCount),
                    subtitle:
                        '${dashboard.exclusive.invoiceCount} exclusive / ${dashboard.inclusive.invoiceCount} inclusive',
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'Total Invoice Value',
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
                    title: 'Output CGST',
                    value: GstReportFormatters.money(dashboard.cgstAmount),
                    icon: Icons.south_west_rounded,
                    accentColor: GstReportColors.success,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'Output SGST',
                    value: GstReportFormatters.money(dashboard.sgstAmount),
                    icon: Icons.south_east_rounded,
                    accentColor: GstReportColors.success,
                  ),
                ),
                _MetricBox(
                  width: cardWidth,
                  child: GstReportMetricCard(
                    title: 'Output IGST',
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
                    title: 'Review Queue Value',
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
                    title: 'Audit Alerts',
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

class _DashboardFilingContext extends StatelessWidget {
  const _DashboardFilingContext({
    required this.identity,
    required this.documents,
  });

  final GstReportShopIdentity identity;
  final List<Gstr1DocumentSummaryRow> documents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShopIdentityStrip(identity: identity),
        if (documents.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InvoiceSeriesStrip(rows: documents),
        ],
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
    return SizedBox(
      width: width,
      height: GstDashboardView._metricCardHeight,
      child: child,
    );
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
                icon: Icons.calculate_rounded,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _IdentityChip(label: 'Shop', value: identity.shopName),
            _IdentityChip(
              label: 'GSTIN',
              value: identity.gstin.isEmpty ? 'Not configured' : identity.gstin,
            ),
            _IdentityChip(
              label: 'Registered State Code',
              value:
                  identity.stateCode.isEmpty ? 'Pending' : identity.stateCode,
            ),
            _IdentityChip(
              label: 'Registered State',
              value:
                  identity.stateName.isEmpty ? 'Pending' : identity.stateName,
            ),
            if (identity.configuredStateName.isNotEmpty)
              _IdentityChip(
                label: 'Profile State',
                value: identity.configuredStateName,
                accent: identity.hasStateMismatch
                    ? GstReportColors.danger
                    : GstReportColors.success,
              ),
          ],
        ),
        if (identity.hasStateMismatch) ...[
          const SizedBox(height: 12),
          _StateMismatchNotice(identity: identity),
        ],
      ],
    );
  }
}

class _InvoiceSeriesStrip extends StatelessWidget {
  const _InvoiceSeriesStrip({required this.rows});

  final List<Gstr1DocumentSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final row in rows)
          _InvoiceSeriesChip(
            fromNumber: row.fromNumber,
            toNumber: row.toNumber,
            totalIssued: row.totalIssued,
          ),
      ],
    );
  }
}

class _InvoiceSeriesChip extends StatelessWidget {
  const _InvoiceSeriesChip({
    required this.fromNumber,
    required this.toNumber,
    required this.totalIssued,
  });

  final String fromNumber;
  final String toNumber;
  final int totalIssued;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 380),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GstReportColors.taxGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: GstReportColors.taxGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Invoice Series',
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$fromNumber to $toNumber',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$totalIssued invoices issued',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMismatchNotice extends StatelessWidget {
  const _StateMismatchNotice({required this.identity});

  final GstReportShopIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GstReportColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border:
            Border.all(color: GstReportColors.danger.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: GstReportColors.danger,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'GSTIN state is ${identity.stateName}, but shop profile state is ${identity.configuredStateName}. Correct the shop identity before filing.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GstReportStyles.body.copyWith(
                color: GstReportColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityChip extends StatelessWidget {
  const _IdentityChip({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? GstReportColors.bodyBorder;
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent == null
            ? GstReportColors.bodySubtle
            : effectiveAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: accent == null
              ? GstReportColors.bodyBorder
              : effectiveAccent.withValues(alpha: 0.24),
        ),
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
      title: 'GST Rate Wise Outward Summary',
      subtitle:
          'Rate-level taxable value, output tax and invoice value for return cross-checks',
      icon: Icons.percent_rounded,
      child: rows.isEmpty
          ? const GstReportEmptyState(message: 'No tax-rate summary found.')
          : _RateSummaryGrid(rows: rows),
    );
  }
}

class _RateSummaryGrid extends StatelessWidget {
  const _RateSummaryGrid({required this.rows});

  final List<GstRateSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    const minWidth = 1040.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                const _RateSummaryHeader(),
                const SizedBox(height: 8),
                for (final row in rows) ...[
                  _RateSummaryDataRow(row: row),
                  if (row != rows.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RateSummaryHeader extends StatelessWidget {
  const _RateSummaryHeader();

  @override
  Widget build(BuildContext context) {
    return const _RateSummaryLine(
      cells: [
        _RateSummaryCell(label: 'Rate', flex: 8),
        _RateSummaryCell(label: 'Invoices', flex: 9),
        _RateSummaryCell(label: 'Taxable Value', flex: 14),
        _RateSummaryCell(label: 'Output CGST', flex: 12),
        _RateSummaryCell(label: 'Output SGST', flex: 12),
        _RateSummaryCell(label: 'Output IGST', flex: 12),
        _RateSummaryCell(label: 'Output GST', flex: 12),
        _RateSummaryCell(label: 'Invoice Value', flex: 15),
      ],
      isHeader: true,
    );
  }
}

class _RateSummaryDataRow extends StatelessWidget {
  const _RateSummaryDataRow({required this.row});

  final GstRateSummaryRow row;

  @override
  Widget build(BuildContext context) {
    return _RateSummaryLine(
      cells: [
        _RateSummaryCell(
          label: GstReportFormatters.rate(row.rate),
          flex: 8,
        ),
        _RateSummaryCell(
          label: GstReportFormatters.count(row.invoiceCount),
          flex: 9,
        ),
        _RateSummaryCell(
          label: GstReportFormatters.money(row.taxableAmount),
          flex: 14,
        ),
        _RateSummaryCell(
          label: GstReportFormatters.money(row.cgstAmount),
          flex: 12,
        ),
        _RateSummaryCell(
          label: GstReportFormatters.money(row.sgstAmount),
          flex: 12,
        ),
        _RateSummaryCell(
          label: GstReportFormatters.money(row.igstAmount),
          flex: 12,
        ),
        _RateSummaryCell(
          label: GstReportFormatters.money(row.gstAmount),
          flex: 12,
        ),
        _RateSummaryCell(
          label: GstReportFormatters.money(row.invoiceValue),
          flex: 15,
        ),
      ],
    );
  }
}

class _RateSummaryLine extends StatelessWidget {
  const _RateSummaryLine({
    required this.cells,
    this.isHeader = false,
  });

  final List<_RateSummaryCell> cells;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            isHeader ? GstReportColors.bodySubtle : GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: Row(
        children: [
          for (var index = 0; index < cells.length; index++) ...[
            Expanded(
              flex: cells[index].flex,
              child: Text(
                cells[index].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GstReportStyles.body.copyWith(
                  color: isHeader
                      ? GstReportColors.textMuted
                      : GstReportColors.textPrimary,
                  fontSize: isHeader ? 11.5 : 12.5,
                  fontWeight: isHeader ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ),
            if (index != cells.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _RateSummaryCell {
  const _RateSummaryCell({
    required this.label,
    required this.flex,
  });

  final String label;
  final int flex;
}
