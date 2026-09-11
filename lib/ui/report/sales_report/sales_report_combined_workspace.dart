import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/sales_report/sales_report_controller.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';
import 'bill_ledger/sales_report_invoice_ledger.dart';
import 'item_ledger/sales_report_item_ledger.dart';
import 'summary/sales_report_sales_overview.dart';
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
        SalesReportSalesOverview(
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: SalesReportColors.goldGradientStart.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: SalesReportColors.brandGold.withValues(alpha: 0.28),
            ),
          ),
          child: const Icon(
            Icons.dashboard_customize_rounded,
            size: 22,
            color: SalesReportColors.brandGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Metal Drilldown - $periodLabel',
                style: SalesReportStyles.pageTitle.copyWith(
                  color: SalesReportColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Monthly metal-wise sales, invoice count and net weight performance',
                style: SalesReportStyles.body.copyWith(
                  color: SalesReportColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
