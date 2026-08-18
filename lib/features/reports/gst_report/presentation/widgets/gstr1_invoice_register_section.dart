import 'package:flutter/material.dart';

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class Gstr1InvoiceRegisterSection extends StatelessWidget {
  const Gstr1InvoiceRegisterSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<GstInvoiceRow> rows;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: title,
      subtitle: subtitle,
      icon: Icons.receipt_long_rounded,
      trailing: _RegisterCountPill(count: rows.length, accent: accent),
      child: rows.isEmpty
          ? GstReportEmptyState(message: 'No $title found for this period.')
          : _InvoiceRegisterGrid(rows: rows, accent: accent),
    );
  }
}

class _InvoiceRegisterGrid extends StatelessWidget {
  const _InvoiceRegisterGrid({
    required this.rows,
    required this.accent,
  });

  final List<GstInvoiceRow> rows;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const minWidth = 1480.0;
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
                const _InvoiceHeaderLine(),
                const SizedBox(height: 8),
                for (final row in rows) ...[
                  _InvoiceDataLine(row: row, accent: accent),
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

class _InvoiceHeaderLine extends StatelessWidget {
  const _InvoiceHeaderLine();

  @override
  Widget build(BuildContext context) {
    return const _InvoiceLine(
      isHeader: true,
      cells: [
        _InvoiceCell(label: 'Invoice No', flex: 15),
        _InvoiceCell(label: 'Date', flex: 10),
        _InvoiceCell(label: 'Customer', flex: 17),
        _InvoiceCell(label: 'GSTIN', flex: 14),
        _InvoiceCell(label: 'Place of Supply', flex: 12),
        _InvoiceCell(label: 'Pricing', flex: 10),
        _InvoiceCell(label: 'Taxable Value', flex: 12),
        _InvoiceCell(label: 'CGST', flex: 10),
        _InvoiceCell(label: 'SGST', flex: 10),
        _InvoiceCell(label: 'IGST', flex: 10),
        _InvoiceCell(label: 'Output GST', flex: 11),
        _InvoiceCell(label: 'Invoice Value', flex: 13),
      ],
    );
  }
}

class _InvoiceDataLine extends StatelessWidget {
  const _InvoiceDataLine({
    required this.row,
    required this.accent,
  });

  final GstInvoiceRow row;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _InvoiceLine(
      accent: accent,
      cells: [
        _InvoiceCell(label: row.invoiceNo, flex: 15, strong: true),
        _InvoiceCell(label: GstReportFormatters.date(row.invoiceDate), flex: 10),
        _InvoiceCell(label: row.customerName, flex: 17),
        _InvoiceCell(label: _gstinLabel(row), flex: 14),
        _InvoiceCell(label: _fallback(row.placeOfSupply), flex: 12),
        _InvoiceCell(label: _pricingLabel(row.gstPricingMode), flex: 10),
        _InvoiceCell(
          label: GstReportFormatters.money(row.taxableAmount),
          flex: 12,
          strong: true,
        ),
        _InvoiceCell(label: GstReportFormatters.money(row.cgstAmount), flex: 10),
        _InvoiceCell(label: GstReportFormatters.money(row.sgstAmount), flex: 10),
        _InvoiceCell(label: GstReportFormatters.money(row.igstAmount), flex: 10),
        _InvoiceCell(
          label: GstReportFormatters.money(row.gstAmount),
          flex: 11,
          strong: true,
        ),
        _InvoiceCell(
          label: GstReportFormatters.money(row.invoiceValue),
          flex: 13,
          strong: true,
        ),
      ],
    );
  }

  static String _fallback(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Pending' : trimmed;
  }

  static String _gstinLabel(GstInvoiceRow row) {
    final value = row.customerGstin.trim();
    if (value.isNotEmpty) return value;
    return row.isB2B ? 'Missing' : 'Unregistered';
  }

  static String _pricingLabel(String value) {
    return value.trim().toUpperCase() == 'GST_INCLUSIVE'
        ? 'Inclusive'
        : 'Exclusive';
  }
}

class _InvoiceLine extends StatelessWidget {
  const _InvoiceLine({
    required this.cells,
    this.isHeader = false,
    this.accent,
  });

  final List<_InvoiceCell> cells;
  final bool isHeader;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final rowAccent = accent ?? GstReportColors.taxGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHeader
            ? GstReportColors.bodySubtle
            : rowAccent.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHeader
              ? GstReportColors.bodyBorder
              : rowAccent.withValues(alpha: 0.12),
        ),
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

class _InvoiceCell {
  const _InvoiceCell({
    required this.label,
    required this.flex,
    this.strong = false,
  });

  final String label;
  final int flex;
  final bool strong;
}

class _RegisterCountPill extends StatelessWidget {
  const _RegisterCountPill({
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
        '${GstReportFormatters.count(count)} invoices',
        style: GstReportStyles.body.copyWith(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
