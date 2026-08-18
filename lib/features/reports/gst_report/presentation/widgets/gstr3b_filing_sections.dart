import 'package:flutter/material.dart';

import '../../domain/gstr3b_filing_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class Gstr3bReadinessPanel extends StatelessWidget {
  const Gstr3bReadinessPanel({
    super.key,
    required this.readiness,
  });

  final Gstr3bReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final accent = readiness.canFile ? GstReportColors.success : GstReportColors.danger;
    return GstReportPanel(
      title: 'GSTR-3B Filing Readiness',
      subtitle: readiness.canFile
          ? 'Sales liability checks are clear; verify ITC and portal cash ledger'
          : 'Resolve blockers before filing GSTR-3B',
      icon: readiness.canFile ? Icons.verified_rounded : Icons.error_outline_rounded,
      trailing: _StatusPill(
        label: readiness.canFile ? 'Ready to Review' : 'Action Required',
        accent: accent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _CounterTile(
                      title: 'Blocking Issues',
                      value: readiness.blockerCount,
                      accent: readiness.blockerCount == 0
                          ? GstReportColors.success
                          : GstReportColors.danger,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _CounterTile(
                      title: 'Review Warnings',
                      value: readiness.warningCount,
                      accent: readiness.warningCount == 0
                          ? GstReportColors.success
                          : GstReportColors.warning,
                    ),
                  ),
                ],
              );
            },
          ),
          if (readiness.blockers.isNotEmpty ||
              readiness.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final message in readiness.blockers)
              _ReadinessMessage(
                message: message,
                accent: GstReportColors.danger,
                icon: Icons.priority_high_rounded,
              ),
            for (final message in readiness.warnings)
              _ReadinessMessage(
                message: message,
                accent: GstReportColors.warning,
                icon: Icons.info_outline_rounded,
              ),
          ],
        ],
      ),
    );
  }
}

class Gstr3bTable31Panel extends StatelessWidget {
  const Gstr3bTable31Panel({
    super.key,
    required this.rows,
  });

  final List<Gstr3bTaxRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Table 3.1 - Tax Liability Summary',
      subtitle: 'Outward supplies and inward supplies liable to reverse charge',
      icon: Icons.summarize_outlined,
      child: _Grid(
        minWidth: 1180,
        headers: const [
          _GridCell('Table', 8),
          _GridCell('Nature of Supply', 22),
          _GridCell('Taxable Value', 14),
          _GridCell('IGST', 11),
          _GridCell('CGST', 11),
          _GridCell('SGST', 11),
          _GridCell('Cess', 9),
          _GridCell('Total Tax', 12),
          _GridCell('Note', 22),
        ],
        rows: [
          for (final row in rows)
            [
              _GridCell(row.code, 8, strong: true),
              _GridCell(row.title, 22, strong: true),
              _GridCell(GstReportFormatters.money(row.taxableValue), 14),
              _GridCell(GstReportFormatters.money(row.igst), 11),
              _GridCell(GstReportFormatters.money(row.cgst), 11),
              _GridCell(GstReportFormatters.money(row.sgst), 11),
              _GridCell(GstReportFormatters.money(row.cess), 9),
              _GridCell(
                GstReportFormatters.money(row.totalTax),
                12,
                strong: true,
              ),
              _GridCell(row.note, 22),
            ],
        ],
      ),
    );
  }
}

class Gstr3bTable32Panel extends StatelessWidget {
  const Gstr3bTable32Panel({
    super.key,
    required this.rows,
  });

  final List<Gstr3bInterStateRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Table 3.2 - Inter-State Supplies',
      subtitle: 'Unregistered consumer supplies auto-derived from IGST B2C sales',
      icon: Icons.map_outlined,
      child: rows.isEmpty
          ? const GstReportEmptyState(
              message: 'No inter-state B2C consumer supplies for this period.',
            )
          : _Grid(
              minWidth: 760,
              headers: const [
                _GridCell('Place of Supply', 18),
                _GridCell('Recipient Type', 18),
                _GridCell('Taxable Value', 14),
                _GridCell('IGST', 12),
              ],
              rows: [
                for (final row in rows)
                  [
                    _GridCell(row.placeOfSupply, 18, strong: true),
                    const _GridCell('Unregistered Person', 18),
                    _GridCell(
                      GstReportFormatters.money(row.taxableValue),
                      14,
                      strong: true,
                    ),
                    _GridCell(
                      GstReportFormatters.money(row.igst),
                      12,
                      strong: true,
                    ),
                  ],
              ],
            ),
    );
  }
}

class Gstr3bItcPanel extends StatelessWidget {
  const Gstr3bItcPanel({
    super.key,
    required this.rows,
  });

  final List<Gstr3bItcRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Table 4 - Eligible ITC',
      subtitle: 'Keep this locked until Purchase Report and GSTR-2B reconciliation are live',
      icon: Icons.inventory_2_outlined,
      child: _Grid(
        minWidth: 1060,
        headers: const [
          _GridCell('Section', 9),
          _GridCell('ITC Type', 24),
          _GridCell('IGST', 10),
          _GridCell('CGST', 10),
          _GridCell('SGST', 10),
          _GridCell('Cess', 10),
          _GridCell('Status', 24),
        ],
        rows: [
          for (final row in rows)
            [
              _GridCell(row.section, 9, strong: true),
              _GridCell(row.title, 24, strong: true),
              _GridCell(GstReportFormatters.money(row.igst), 10),
              _GridCell(GstReportFormatters.money(row.cgst), 10),
              _GridCell(GstReportFormatters.money(row.sgst), 10),
              _GridCell(GstReportFormatters.money(row.cess), 10),
              _GridCell(row.status, 24),
            ],
        ],
      ),
    );
  }
}

class Gstr3bExemptInwardPanel extends StatelessWidget {
  const Gstr3bExemptInwardPanel({
    super.key,
    required this.rows,
  });

  final List<Gstr3bExemptInwardRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Table 5 - Exempt / Nil / Non-GST Inward Supplies',
      subtitle: 'Purchase-side summary; currently held for purchase classification',
      icon: Icons.receipt_outlined,
      child: _Grid(
        minWidth: 860,
        headers: const [
          _GridCell('Nature of Supply', 24),
          _GridCell('Inter-State Value', 14),
          _GridCell('Intra-State Value', 14),
          _GridCell('Status', 24),
        ],
        rows: [
          for (final row in rows)
            [
              _GridCell(row.title, 24, strong: true),
              _GridCell(GstReportFormatters.money(row.interStateValue), 14),
              _GridCell(GstReportFormatters.money(row.intraStateValue), 14),
              _GridCell(row.status, 24),
            ],
        ],
      ),
    );
  }
}

class Gstr3bPaymentPanel extends StatelessWidget {
  const Gstr3bPaymentPanel({
    super.key,
    required this.rows,
  });

  final List<Gstr3bPaymentRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: 'Table 6.1 - Payment of Tax',
      subtitle: 'Cash payable before portal interest, late fee and ledger adjustment',
      icon: Icons.payments_outlined,
      child: _Grid(
        minWidth: 980,
        headers: const [
          _GridCell('Tax Head', 12),
          _GridCell('Tax Payable', 14),
          _GridCell('ITC Available', 14),
          _GridCell('Cash Payable', 14),
          _GridCell('Interest', 12),
          _GridCell('Late Fee', 12),
        ],
        rows: [
          for (final row in rows)
            [
              _GridCell(row.taxHead, 12, strong: true),
              _GridCell(GstReportFormatters.money(row.taxPayable), 14),
              _GridCell(GstReportFormatters.money(row.itcAvailable), 14),
              _GridCell(
                GstReportFormatters.money(row.cashPayable),
                14,
                strong: true,
              ),
              _GridCell(GstReportFormatters.money(row.interest), 12),
              _GridCell(GstReportFormatters.money(row.lateFee), 12),
            ],
        ],
      ),
    );
  }
}

class Gstr3bFilingChecklistPanel extends StatelessWidget {
  const Gstr3bFilingChecklistPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _ChecklistItem(
        title: 'GSTR-1 / IFF Liability',
        note: 'Match outward tax with Table 3.1(a).',
        icon: Icons.receipt_long_rounded,
      ),
      _ChecklistItem(
        title: 'GSTR-2B ITC Statement',
        note: 'Download from portal before entering Table 4.',
        icon: Icons.download_for_offline_outlined,
      ),
      _ChecklistItem(
        title: 'Purchase Invoices',
        note: 'Keep supplier invoices for ITC evidence.',
        icon: Icons.inventory_2_outlined,
      ),
      _ChecklistItem(
        title: 'RCM Expenses',
        note: 'Check rent, legal, transport or other reverse charge items.',
        icon: Icons.assignment_returned_outlined,
      ),
      _ChecklistItem(
        title: 'Cash Ledger / PMT-06',
        note: 'For QRMP month 1 and 2, pay through monthly challan.',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _ChecklistItem(
        title: 'Interest / Late Fee',
        note: 'Confirm portal-calculated amount before final filing.',
        icon: Icons.schedule_rounded,
      ),
    ];

    return GstReportPanel(
      title: 'Documents and Portal Checklist',
      subtitle: 'Keep these ready before final GSTR-3B filing',
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
                SizedBox(width: width, child: _ChecklistTile(item: item)),
            ],
          );
        },
      ),
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

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GstReportStyles.body.copyWith(
                color: GstReportColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$value',
            style: GstReportStyles.sectionTitle.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _ReadinessMessage extends StatelessWidget {
  const _ReadinessMessage({
    required this.message,
    required this.accent,
    required this.icon,
  });

  final String message;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GstReportStyles.body.copyWith(
                color: GstReportColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
        border: Border.all(color: accent.withValues(alpha: 0.18)),
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

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.item});

  final _ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
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
            child: Icon(item.icon, color: GstReportColors.taxGreen, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.note,
                  maxLines: 2,
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

class _ChecklistItem {
  const _ChecklistItem({
    required this.title,
    required this.note,
    required this.icon,
  });

  final String title;
  final String note;
  final IconData icon;
}
