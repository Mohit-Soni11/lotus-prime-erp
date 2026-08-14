import 'package:flutter/material.dart';

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_panel.dart';

class Gstr1RegisterView extends StatelessWidget {
  const Gstr1RegisterView({
    super.key,
    required this.snapshot,
  });

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InvoiceSection(
          title: 'B2B Invoices',
          subtitle: 'Registered customer outward supplies',
          rows: snapshot.gstr1B2bInvoices,
        ),
        const SizedBox(height: 16),
        _InvoiceSection(
          title: 'B2C Invoices',
          subtitle: 'Consumer and unregistered customer outward supplies',
          rows: snapshot.gstr1B2cInvoices,
        ),
        const SizedBox(height: 16),
        const GstReportPanel(
          title: 'Credit / Debit Notes',
          subtitle: 'Future-ready section for sales return workflow',
          icon: Icons.post_add_rounded,
          child: GstReportEmptyState(
            message: 'No credit or debit note data is available yet.',
            icon: Icons.pending_actions_rounded,
          ),
        ),
      ],
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<GstInvoiceRow> rows;

  @override
  Widget build(BuildContext context) {
    return GstReportPanel(
      title: title,
      subtitle: subtitle,
      icon: Icons.receipt_long_rounded,
      trailing: _CountPill(count: rows.length),
      child: rows.isEmpty
          ? GstReportEmptyState(message: 'No $title found for this period.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(
                  GstReportColors.bodySubtle,
                ),
                columns: const [
                  DataColumn(label: Text('Invoice No')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('GSTIN')),
                  DataColumn(label: Text('Place')),
                  DataColumn(label: Text('Taxable')),
                  DataColumn(label: Text('CGST')),
                  DataColumn(label: Text('SGST')),
                  DataColumn(label: Text('IGST')),
                  DataColumn(label: Text('GST')),
                  DataColumn(label: Text('Total')),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [
                        DataCell(Text(row.invoiceNo)),
                        DataCell(Text(GstReportFormatters.date(
                          row.invoiceDate,
                        ))),
                        DataCell(_ConstrainedCell(row.customerName)),
                        DataCell(Text(row.customerGstin.isEmpty
                            ? '-'
                            : row.customerGstin)),
                        DataCell(_ConstrainedCell(
                          row.placeOfSupply.isEmpty ? '-' : row.placeOfSupply,
                        )),
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

class _ConstrainedCell extends StatelessWidget {
  const _ConstrainedCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GstReportColors.taxGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        GstReportFormatters.count(count),
        style: GstReportStyles.body.copyWith(
          color: GstReportColors.taxGreen,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
