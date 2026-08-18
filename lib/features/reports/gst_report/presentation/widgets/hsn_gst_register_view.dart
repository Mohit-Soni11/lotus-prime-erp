import 'package:flutter/material.dart';

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class HsnGstRegisterView extends StatelessWidget {
  const HsnGstRegisterView({
    super.key,
    required this.snapshot,
  });

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final b2bRows = _rowsFor('B2B');
    final b2cRows = _rowsFor('B2C');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HsnGuidancePanel(
          b2bCount: b2bRows.length,
          b2cCount: b2cRows.length,
        ),
        const SizedBox(height: 16),
        _HsnTable12Panel(
          title: 'Table 12 - HSN Summary for B2B Sales',
          subtitle: 'Registered-customer outward supplies reported in GSTR-1',
          rows: b2bRows,
          accent: GstReportColors.information,
        ),
        const SizedBox(height: 16),
        _HsnTable12Panel(
          title: 'Table 12 - HSN Summary for B2C Sales',
          subtitle: 'Consumer outward supplies reported in GSTR-1',
          rows: b2cRows,
          accent: GstReportColors.success,
        ),
      ],
    );
  }

  List<GstHsnSummaryRow> _rowsFor(String type) {
    return snapshot.hsnSummary
        .where((row) => row.invoiceType.trim().toUpperCase() == type)
        .toList(growable: false);
  }
}

class _HsnGuidancePanel extends StatelessWidget {
  const _HsnGuidancePanel({
    required this.b2bCount,
    required this.b2cCount,
  });

  final int b2bCount;
  final int b2cCount;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'HSN Table 12 Filing Register',
      subtitle: 'This is not a separate return; it is GSTR-1 Table 12 outward sales HSN data',
      icon: GstReportIcons.hsn,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 980
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 680
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: const _GuidanceTile(
                  title: 'Portal Location',
                  value: 'GSTR-1 Table 12',
                  note: 'Enter from the GSTR-1 return, not separately.',
                  icon: Icons.fact_check_outlined,
                  accent: GstReportColors.taxGreen,
                ),
              ),
              SizedBox(
                width: width,
                child: _GuidanceTile(
                  title: 'B2B Sales HSN',
                  value: '$b2bCount rows',
                  note: 'Sales to customers with GSTIN.',
                  icon: Icons.business_center_rounded,
                  accent: GstReportColors.information,
                ),
              ),
              SizedBox(
                width: width,
                child: _GuidanceTile(
                  title: 'B2C Sales HSN',
                  value: '$b2cCount rows',
                  note: 'Sales to unregistered / walk-in customers.',
                  icon: Icons.storefront_rounded,
                  accent: GstReportColors.success,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuidanceTile extends StatelessWidget {
  const _GuidanceTile({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HsnTable12Panel extends StatelessWidget {
  const _HsnTable12Panel({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<GstHsnSummaryRow> rows;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: title,
      subtitle: subtitle,
      icon: GstReportIcons.hsn,
      trailing: _CountPill(count: rows.length, accent: accent),
      child: rows.isEmpty
          ? const GstReportEmptyState(
              message: 'No HSN rows found for this sales type.',
            )
          : _HsnPortalGrid(rows: rows),
    );
  }
}

class _HsnPortalGrid extends StatelessWidget {
  const _HsnPortalGrid({required this.rows});

  final List<GstHsnSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return _Grid(
      minWidth: 1260,
      headers: const [
        _GridCell('HSN/SAC', 10),
        _GridCell('Description', 18),
        _GridCell('UQC', 7),
        _GridCell('Total Quantity', 11),
        _GridCell('Total Value', 13),
        _GridCell('Taxable Value', 13),
        _GridCell('Rate', 8),
        _GridCell('IGST', 10),
        _GridCell('CGST', 10),
        _GridCell('SGST', 10),
        _GridCell('Cess', 8),
        _GridCell('Invoices', 9),
      ],
      rows: [
        for (final row in rows)
          [
            _GridCell(row.hsnCode, 10, strong: true),
            _GridCell(row.description, 18),
            const _GridCell('PCS', 7),
            _GridCell(GstReportFormatters.count(row.quantity), 11),
            _GridCell(
              GstReportFormatters.money(row.invoiceValue),
              13,
              strong: true,
            ),
            _GridCell(
              GstReportFormatters.money(row.taxableAmount),
              13,
              strong: true,
            ),
            _GridCell(GstReportFormatters.rate(row.gstRate), 8),
            _GridCell(GstReportFormatters.money(row.igstAmount), 10),
            _GridCell(GstReportFormatters.money(row.cgstAmount), 10),
            _GridCell(GstReportFormatters.money(row.sgstAmount), 10),
            _GridCell(GstReportFormatters.money(0), 8),
            _GridCell(GstReportFormatters.count(row.invoiceCount), 9),
          ],
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.minWidth,
    required this.headers,
    required this.rows,
  });

  final double minWidth;
  final List<_GridCell> headers;
  final List<List<_GridCell>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _GridLine(cells: headers, isHeader: true),
                const SizedBox(height: 8),
                for (final row in rows) ...[
                  _GridLine(cells: row),
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

class _GridLine extends StatelessWidget {
  const _GridLine({
    required this.cells,
    this.isHeader = false,
  });

  final List<_GridCell> cells;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHeader ? GstReportColors.bodySubtle : GstReportColors.bodyPanel,
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
                  fontWeight: isHeader || cells[index].strong
                      ? FontWeight.w900
                      : FontWeight.w700,
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

class _GridCell {
  const _GridCell(this.label, this.flex, {this.strong = false});

  final String label;
  final int flex;
  final bool strong;
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.count,
    required this.accent,
  });

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Text(
        '${GstReportFormatters.count(count)} rows',
        style: GstReportStyles.body.copyWith(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
