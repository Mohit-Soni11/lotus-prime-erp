import 'package:flutter/material.dart';

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import 'gst_report_metric_card.dart';
import 'gst_report_panel.dart';

class Gstr3bSummaryView extends StatelessWidget {
  const Gstr3bSummaryView({
    super.key,
    required this.snapshot,
  });

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final summary = snapshot.gstr3b;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 980
                ? (constraints.maxWidth - 42) / 4
                : constraints.maxWidth >= 620
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: width,
                  child: GstReportMetricCard(
                    title: 'Outward Taxable Supply',
                    value: GstReportFormatters.money(
                      summary.outwardTaxableValue,
                    ),
                    icon: Icons.trending_up_rounded,
                    accentColor: GstReportColors.information,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: GstReportMetricCard(
                    title: 'Output CGST',
                    value: GstReportFormatters.money(summary.outwardCgst),
                    icon: Icons.account_balance_rounded,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: GstReportMetricCard(
                    title: 'Output SGST',
                    value: GstReportFormatters.money(summary.outwardSgst),
                    icon: Icons.account_balance_rounded,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: GstReportMetricCard(
                    title: 'Output IGST',
                    value: GstReportFormatters.money(summary.outwardIgst),
                    icon: Icons.sync_alt_rounded,
                    accentColor: GstReportColors.warning,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        GstReportPanel(
          title: 'GSTR-3B Table 3.1',
          subtitle: 'Outward supplies and tax liability summary',
          icon: GstReportIcons.gstr3b,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 30,
              headingRowColor: WidgetStateProperty.all(
                GstReportColors.bodySubtle,
              ),
              columns: const [
                DataColumn(label: Text('Nature of Supplies')),
                DataColumn(label: Text('Taxable Value')),
                DataColumn(label: Text('IGST')),
                DataColumn(label: Text('CGST')),
                DataColumn(label: Text('SGST')),
                DataColumn(label: Text('Total Tax')),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('Outward taxable supplies')),
                  DataCell(Text(GstReportFormatters.money(
                    summary.outwardTaxableValue,
                  ))),
                  DataCell(Text(GstReportFormatters.money(
                    summary.outwardIgst,
                  ))),
                  DataCell(Text(GstReportFormatters.money(
                    summary.outwardCgst,
                  ))),
                  DataCell(Text(GstReportFormatters.money(
                    summary.outwardSgst,
                  ))),
                  DataCell(Text(GstReportFormatters.money(
                    summary.netTaxPayable,
                  ))),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Nil / exempt / non-taxable')),
                  DataCell(Text(GstReportFormatters.money(
                    summary.nilExemptNonGstValue,
                  ))),
                  const DataCell(Text('-')),
                  const DataCell(Text('-')),
                  const DataCell(Text('-')),
                  const DataCell(Text('-')),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GstReportPanel(
          title: 'Input Tax Credit',
          subtitle: 'Will become live after Purchase Report integration',
          icon: Icons.inventory_2_outlined,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GstReportColors.bodySubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GstReportColors.bodyBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_clock_rounded,
                  color: GstReportColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ITC values are intentionally parked until purchase GST data is hardened.',
                    style: GstReportStyles.body,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GstReportPanel(
          title: 'Output GST Liability',
          subtitle: 'CGST + SGST + IGST before purchase ITC adjustment',
          icon: Icons.payments_outlined,
          child: Text(
            GstReportFormatters.money(summary.netTaxPayable),
            style: GstReportStyles.pageTitle.copyWith(
              fontSize: 30,
              color: GstReportColors.danger,
            ),
          ),
        ),
      ],
    );
  }
}
