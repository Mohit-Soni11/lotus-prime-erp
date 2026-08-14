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
    final rows = snapshot.hsnSummary;
    return GstReportPanel(
      title: 'HSN/SAC GST Register',
      subtitle: 'B2B and B2C outward HSN summary for GST filing',
      icon: GstReportIcons.hsn,
      child: rows.isEmpty
          ? const GstReportEmptyState(
              message: 'No HSN/SAC GST rows found for this period.',
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 22,
                headingRowColor: WidgetStateProperty.all(
                  GstReportColors.bodySubtle,
                ),
                columns: const [
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('HSN')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Rate')),
                  DataColumn(label: Text('Invoices')),
                  DataColumn(label: Text('Lines')),
                  DataColumn(label: Text('Qty/Pcs')),
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
                        DataCell(_TypePill(type: row.invoiceType)),
                        DataCell(Text(row.hsnCode)),
                        DataCell(SizedBox(
                          width: 210,
                          child: Text(
                            row.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        DataCell(Text(GstReportFormatters.rate(row.gstRate))),
                        DataCell(Text(GstReportFormatters.count(
                          row.invoiceCount,
                        ))),
                        DataCell(Text(GstReportFormatters.count(
                          row.lineCount,
                        ))),
                        DataCell(Text(GstReportFormatters.count(
                          row.quantity,
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

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isB2b = type == 'B2B';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (isB2b ? GstReportColors.taxGreen : GstReportColors.information)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        type,
        style: GstReportStyles.body.copyWith(
          color: isB2b ? GstReportColors.taxGreen : GstReportColors.information,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
