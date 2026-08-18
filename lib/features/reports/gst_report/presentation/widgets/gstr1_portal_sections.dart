import 'package:flutter/material.dart';

import '../../domain/gstr1_filing_models.dart';
import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class Gstr1B2cSmallSummarySection extends StatelessWidget {
  const Gstr1B2cSmallSummarySection({
    super.key,
    required this.rows,
  });

  final List<Gstr1B2cSmallSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'B2C Small Consolidated Summary',
      subtitle: 'Table 7 summary grouped by place of supply and GST rate',
      icon: Icons.groups_2_rounded,
      child: rows.isEmpty
          ? const GstReportEmptyState(
              message: 'No B2C Small outward supplies for this period.',
            )
          : _PortalGrid(
              minWidth: 1120,
              headers: const [
                _GridCell('Place of Supply', 16),
                _GridCell('Supply Type', 12),
                _GridCell('Rate', 8),
                _GridCell('Invoices', 9),
                _GridCell('Taxable Value', 14),
                _GridCell('CGST', 10),
                _GridCell('SGST', 10),
                _GridCell('IGST', 10),
                _GridCell('Output GST', 11),
                _GridCell('Invoice Value', 13),
              ],
              rows: [
                for (final row in rows)
                  [
                    _GridCell(row.placeOfSupply, 16, strong: true),
                    _GridCell(row.supplyType, 12),
                    _GridCell(GstReportFormatters.rate(row.rate), 8),
                    _GridCell(GstReportFormatters.count(row.invoiceCount), 9),
                    _GridCell(
                      GstReportFormatters.money(row.taxableValue),
                      14,
                      strong: true,
                    ),
                    _GridCell(GstReportFormatters.money(row.cgstAmount), 10),
                    _GridCell(GstReportFormatters.money(row.sgstAmount), 10),
                    _GridCell(GstReportFormatters.money(row.igstAmount), 10),
                    _GridCell(
                      GstReportFormatters.money(row.outputGst),
                      11,
                      strong: true,
                    ),
                    _GridCell(
                      GstReportFormatters.money(row.invoiceValue),
                      13,
                      strong: true,
                    ),
                  ],
              ],
            ),
    );
  }
}

class Gstr1HsnSplitSummarySection extends StatelessWidget {
  const Gstr1HsnSplitSummarySection({
    super.key,
    required this.b2bRows,
    required this.b2cRows,
    this.showB2b = true,
    this.showB2c = true,
  });

  final List<GstHsnSummaryRow> b2bRows;
  final List<GstHsnSummaryRow> b2cRows;
  final bool showB2b;
  final bool showB2c;

  @override
  Widget build(BuildContext context) {
    final panels = <Widget>[
      if (showB2b)
        _HsnPanel(
          title: 'HSN Summary - B2B Sales',
          rows: b2bRows,
          accent: GstReportColors.information,
        ),
      if (showB2c)
        _HsnPanel(
          title: 'HSN Summary - B2C Sales',
          rows: b2cRows,
          accent: GstReportColors.success,
        ),
    ];

    if (panels.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = panels.length > 1 && constraints.maxWidth >= 980
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final panel in panels) SizedBox(width: width, child: panel),
          ],
        );
      },
    );
  }
}

class Gstr1DocumentIssuedSection extends StatelessWidget {
  const Gstr1DocumentIssuedSection({
    super.key,
    required this.rows,
  });

  final List<Gstr1DocumentSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Documents Issued Summary',
      subtitle: 'Table 13 document range and net issued count',
      icon: Icons.description_outlined,
      child: rows.isEmpty
          ? const GstReportEmptyState(
              message: 'No document summary is available for this period.',
            )
          : _PortalGrid(
              minWidth: 920,
              headers: const [
                _GridCell('Document Type', 18),
                _GridCell('From Number', 18),
                _GridCell('To Number', 18),
                _GridCell('Total Issued', 12),
                _GridCell('Cancelled', 10),
                _GridCell('Net Issued', 10),
              ],
              rows: [
                for (final row in rows)
                  [
                    _GridCell(row.documentType, 18, strong: true),
                    _GridCell(row.fromNumber, 18),
                    _GridCell(row.toNumber, 18),
                    _GridCell(GstReportFormatters.count(row.totalIssued), 12),
                    _GridCell(GstReportFormatters.count(row.cancelled), 10),
                    _GridCell(
                      GstReportFormatters.count(row.netIssued),
                      10,
                      strong: true,
                    ),
                  ],
              ],
            ),
    );
  }
}

class Gstr1AdditionalTablesPanel extends StatelessWidget {
  const Gstr1AdditionalTablesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _StatusTileData(
        title: 'Credit / Debit Notes',
        status: 'No records',
        note: 'Sales return workflow will feed Table 9B.',
        icon: Icons.post_add_rounded,
      ),
      _StatusTileData(
        title: 'Nil / Exempt / Non-GST',
        status: 'No taxable impact',
        note: 'Jewellery taxable sales are reported in regular tables.',
        icon: Icons.block_rounded,
      ),
      _StatusTileData(
        title: 'Advances / Adjustments',
        status: 'No records',
        note: 'Advance tax table will activate with advance workflow.',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _StatusTileData(
        title: 'Amendments',
        status: 'No records',
        note: 'Use only for corrections to previous filed periods.',
        icon: Icons.edit_calendar_outlined,
      ),
      _StatusTileData(
        title: 'Exports / SEZ',
        status: 'Not used',
        note: 'Retail jewellery domestic supplies only.',
        icon: Icons.flight_takeoff_rounded,
      ),
      _StatusTileData(
        title: 'E-Commerce / 9(5)',
        status: 'Not used',
        note: 'No ECO operator collection configured.',
        icon: Icons.store_mall_directory_outlined,
      ),
    ];

    return GstReportPanel(
      title: 'Additional GSTR-1 Tables',
      subtitle: 'Inactive sections are tracked so filing remains complete',
      icon: Icons.fact_check_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 1200
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in items)
                SizedBox(width: width, child: _StatusTile(data: item)),
            ],
          );
        },
      ),
    );
  }
}

class _HsnPanel extends StatelessWidget {
  const _HsnPanel({
    required this.title,
    required this.rows,
    required this.accent,
  });

  final String title;
  final List<GstHsnSummaryRow> rows;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: title,
      subtitle: 'Table 12 HSN-wise outward supply summary',
      icon: Icons.grid_on_rounded,
      trailing: _SmallPill(
        label: '${GstReportFormatters.count(rows.length)} HSN',
        accent: accent,
      ),
      child: rows.isEmpty
          ? const GstReportEmptyState(message: 'No HSN summary rows found.')
          : _PortalGrid(
              minWidth: 760,
              headers: const [
                _GridCell('HSN', 10),
                _GridCell('Description', 18),
                _GridCell('Rate', 8),
                _GridCell('Qty', 8),
                _GridCell('Taxable', 13),
                _GridCell('GST', 11),
                _GridCell('Invoice Value', 13),
              ],
              rows: [
                for (final row in rows)
                  [
                    _GridCell(row.hsnCode, 10, strong: true),
                    _GridCell(row.description, 18),
                    _GridCell(GstReportFormatters.rate(row.gstRate), 8),
                    _GridCell(GstReportFormatters.count(row.quantity), 8),
                    _GridCell(
                      GstReportFormatters.money(row.taxableAmount),
                      13,
                      strong: true,
                    ),
                    _GridCell(
                      GstReportFormatters.money(row.gstAmount),
                      11,
                      strong: true,
                    ),
                    _GridCell(
                      GstReportFormatters.money(row.invoiceValue),
                      13,
                      strong: true,
                    ),
                  ],
              ],
            ),
    );
  }
}

class _PortalGrid extends StatelessWidget {
  const _PortalGrid({
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

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GstReportStyles.body.copyWith(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.data});

  final _StatusTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GstReportColors.bodySubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GstReportColors.taxGreen.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: GstReportColors.taxGreen, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.note,
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

class _StatusTileData {
  const _StatusTileData({
    required this.title,
    required this.status,
    required this.note,
    required this.icon,
  });

  final String title;
  final String status;
  final String note;
  final IconData icon;
}
