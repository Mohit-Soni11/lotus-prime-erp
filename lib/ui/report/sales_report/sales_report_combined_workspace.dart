import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/sales_report/sales_report_controller.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';
import 'bill_ledger/sales_report_invoice_ledger.dart';
import 'item_ledger/sales_report_item_ledger.dart';
import 'summary/sales_report_gst_liability_summary.dart';
import 'summary/sales_report_metal_cards.dart';

class SalesReportCombinedWorkspace extends StatelessWidget {
  final SalesReportController controller;
  final ValueChanged<String> onMetalSelected;

  const SalesReportCombinedWorkspace({
    super.key,
    required this.controller,
    required this.onMetalSelected,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot!;
    final periodLabel = DateFormat('MMMM yyyy').format(
      controller.filter.startDate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalesReportGstLiabilityPanel(
          summary: snapshot.gstLiability,
          periodLabel: periodLabel,
        ),
        const SizedBox(height: 16),
        _MetalDrilldownHeader(periodLabel: periodLabel),
        const SizedBox(height: 10),
        SalesReportMetalCards(
          metals: snapshot.metals,
          selectedMetal: 'ALL',
          periodLabel: periodLabel,
          onMetalSelected: onMetalSelected,
        ),
        const SizedBox(height: 18),
        SalesReportInvoiceLedger(
          invoices: snapshot.invoices,
          items: snapshot.items,
        ),
        const SizedBox(height: 16),
        SalesReportItemLedger(items: snapshot.items),
      ],
    );
  }
}

class _MetalDrilldownHeader extends StatelessWidget {
  final String periodLabel;

  const _MetalDrilldownHeader({required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.dashboard_customize_rounded,
          size: 20,
          color: SalesReportColors.brandGold,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Metal Drill-Down - $periodLabel',
            style: SalesReportStyles.pageTitle.copyWith(fontSize: 18),
          ),
        ),
      ],
    );
  }
}
