import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/screens/customer_metal_purchase_metal_detail_screen.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_table.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_filters/customer_metal_purchase_report_filter_bar.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_metal_cards/customer_metal_purchase_metal_card_grid.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_navigation/customer_metal_purchase_report_command_strip.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_summary/customer_metal_purchase_summary_band.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseReportWorkspace extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;
  final AnimationController animationController;

  const CustomerMetalPurchaseReportWorkspace({
    super.key,
    required this.controller,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final dashboard = controller.dashboardSummary;
    final reportScopeDashboard = controller.reportScopeDashboardSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerMetalPurchaseReportFilterBar(
            controller: controller,
            onOpenCheckoutReport: () =>
                context.push(RoutePaths.customerMetalCheckoutReport),
          ),
          const SizedBox(height: 16),
          _ReportSectionHeader(
            title: 'Metal Drilldown - ${controller.periodLabel}',
            subtitle:
                'Metal-wise customer purchase value, payout and melting checkout summary',
            trailing: _SectionHeaderMetricBadge(
              label: 'Total Vouchers',
              value: reportScopeDashboard.voucherCount.toString(),
              caption: controller.periodLabel,
            ),
          ),
          const SizedBox(height: 10),
          CustomerMetalPurchaseMetalCardGrid(
            periodLabel: controller.periodLabel,
            summaries: controller.visibleMetalSummaries,
            selectedMetal: controller.selectedMetal,
            animationController: animationController,
            onMetalSelected: controller.selectMetal,
            onOpenMetalCheckout: (metal) => _openMetalCheckout(
              context,
              metal,
            ),
          ),
          const SizedBox(height: 16),
          CustomerMetalPurchaseReportSummaryBand(
            summary: dashboard,
            metalSummaries: controller.visibleMetalSummaries,
          ),
          const SizedBox(height: 16),
          CustomerMetalPurchaseReportCommandStrip(controller: controller),
          const SizedBox(height: 14),
          CustomerMetalPurchaseReportBody(
            controller: controller,
          ),
        ],
      ),
    );
  }

  void _openMetalCheckout(
    BuildContext context,
    CustomerMetalPurchaseMetal metal,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerMetalPurchaseMetalDetailScreen(
          metal: metal,
          controller: controller,
        ),
      ),
    );
  }
}

class CustomerMetalPurchaseReportBody extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseReportBody({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    switch (controller.selectedTab) {
      case CustomerMetalPurchaseReportTab.ledger:
        return CustomerMetalPurchaseLedgerTable(
          title: 'Customer Metal Purchase Ledger',
          subtitle: controller.filteredRecordRangeLabel,
          entries: controller.filteredEntries,
        );
      case CustomerMetalPurchaseReportTab.metalSummary:
        return _MetalSummaryTable(
          periodLabel: controller.periodLabel,
          summaries: controller.visibleMetalSummaries,
        );
      case CustomerMetalPurchaseReportTab.sellerSummary:
        return _SellerSummaryTable(
          periodLabel: controller.periodLabel,
          summaries: controller.sellerSummaries,
        );
      case CustomerMetalPurchaseReportTab.pendingPayout:
        return CustomerMetalPurchaseLedgerTable(
          title: 'Pending Seller Payout Ledger',
          subtitle: controller.filteredRecordRangeLabel,
          entries: controller.pendingEntries,
          emptyMessage: 'No pending seller payout found for this period.',
        );
      case CustomerMetalPurchaseReportTab.paymentSummary:
        return _PaymentSummaryPanel(
          periodLabel: controller.periodLabel,
          summary: controller.dashboardSummary,
        );
    }
  }
}

class _ReportSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _ReportSectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leading = Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.18),
            ),
          ),
          child: const Icon(
            Icons.table_chart_rounded,
            size: 21,
            color: PurchaseEntryColors.purchaseAccent,
          ),
        );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                color: Colors.black,
              ),
            ),
          ],
        );

        if (trailing != null && constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(child: copy),
                ],
              ),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: trailing!),
            ],
          );
        }

        return Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(child: copy),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeaderMetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final String caption;

  const _SectionHeaderMetricBadge({
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132, minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF2D27A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalSummaryTable extends StatelessWidget {
  final String periodLabel;
  final Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
      summaries;

  const _MetalSummaryTable({
    required this.periodLabel,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportSectionHeader(
          title: 'Metal Purchase Summary',
          subtitle:
              'Metal-wise settlement value, payout and weight for $periodLabel',
        ),
        const SizedBox(height: 10),
        _ReportSurface(
          padding: EdgeInsets.zero,
          child: DataTable(
            headingRowHeight: 48,
            columnSpacing: 30,
            headingTextStyle: _tableHeadingStyle,
            dataTextStyle: _tableBodyStyle,
            columns: const [
              DataColumn(label: Text('Metal')),
              DataColumn(label: Text('Net Weight')),
              DataColumn(label: Text('Fine Weight')),
              DataColumn(label: Text('Purchase Value')),
              DataColumn(label: Text('Paid')),
              DataColumn(label: Text('Pending')),
              DataColumn(label: Text('Lines')),
              DataColumn(label: Text('Sellers')),
            ],
            rows: [
              for (final entry in summaries.entries)
                DataRow(
                  cells: [
                    DataCell(Text(entry.key.label)),
                    DataCell(
                      Text(
                        CustomerMetalPurchaseFormatters.weight(
                          entry.value.netWeight,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        CustomerMetalPurchaseFormatters.weight(
                          entry.value.fineWeight,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(CustomerMetalPurchaseFormatters.amount(
                        entry.value.amount,
                      )),
                    ),
                    DataCell(
                      Text(CustomerMetalPurchaseFormatters.amount(
                        entry.value.paidAmount,
                      )),
                    ),
                    DataCell(
                      Text(
                        CustomerMetalPurchaseFormatters.amount(
                          entry.value.pendingAmount,
                        ),
                        style: entry.value.pendingAmount > 0.005
                            ? _tableBodyStyle.copyWith(
                                color: PurchaseEntryColors.danger,
                                fontWeight: FontWeight.w900,
                              )
                            : null,
                      ),
                    ),
                    DataCell(Text(entry.value.entryCount.toString())),
                    DataCell(Text(entry.value.customerCount.toString())),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SellerSummaryTable extends StatelessWidget {
  final String periodLabel;
  final List<CustomerMetalPurchaseSellerSummary> summaries;

  const _SellerSummaryTable({
    required this.periodLabel,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportSectionHeader(
            title: 'Seller Purchase Summary',
            subtitle: 'No seller records found for $periodLabel',
          ),
          const SizedBox(height: 10),
          const CustomerMetalPurchaseEmptyState(
            message: 'No seller summary found for this period.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportSectionHeader(
          title: 'Seller Purchase Summary',
          subtitle:
              '${summaries.length} sellers with purchase activity for $periodLabel',
        ),
        const SizedBox(height: 10),
        _ReportSurface(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              columnSpacing: 28,
              headingTextStyle: _tableHeadingStyle,
              dataTextStyle: _tableBodyStyle,
              columns: const [
                DataColumn(label: Text('Seller')),
                DataColumn(label: Text('Mobile')),
                DataColumn(label: Text('Fine Weight')),
                DataColumn(label: Text('Purchase Value')),
                DataColumn(label: Text('Paid')),
                DataColumn(label: Text('Pending')),
                DataColumn(label: Text('Vouchers')),
                DataColumn(label: Text('Lines')),
              ],
              rows: [
                for (final summary in summaries)
                  DataRow(
                    cells: [
                      DataCell(Text(summary.sellerName)),
                      DataCell(Text(summary.mobile ?? 'Not recorded')),
                      DataCell(
                        Text(CustomerMetalPurchaseFormatters.weight(
                          summary.fineWeight,
                        )),
                      ),
                      DataCell(
                        Text(CustomerMetalPurchaseFormatters.amount(
                          summary.amount,
                        )),
                      ),
                      DataCell(
                        Text(CustomerMetalPurchaseFormatters.amount(
                          summary.paidAmount,
                        )),
                      ),
                      DataCell(
                        Text(
                          CustomerMetalPurchaseFormatters.amount(
                            summary.pendingAmount,
                          ),
                          style: summary.pendingAmount > 0.005
                              ? _tableBodyStyle.copyWith(
                                  color: PurchaseEntryColors.danger,
                                  fontWeight: FontWeight.w900,
                                )
                              : null,
                        ),
                      ),
                      DataCell(Text(summary.voucherCount.toString())),
                      DataCell(Text(summary.entryCount.toString())),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentSummaryPanel extends StatelessWidget {
  final String periodLabel;
  final CustomerMetalPurchaseDashboardSummary summary;

  const _PaymentSummaryPanel({
    required this.periodLabel,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportSectionHeader(
          title: 'Payout Mode Summary',
          subtitle: 'Seller payout collection split for $periodLabel',
        ),
        const SizedBox(height: 10),
        _ReportSurface(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 4 : 2;
              const spacing = 12.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _MetricCard(
                    width: width,
                    label: 'Cash Paid',
                    value: CustomerMetalPurchaseFormatters.amount(
                      summary.cashPaid,
                    ),
                    icon: Icons.payments_rounded,
                  ),
                  _MetricCard(
                    width: width,
                    label: 'UPI Paid',
                    value: CustomerMetalPurchaseFormatters.amount(
                      summary.upiPaid,
                    ),
                    icon: Icons.account_balance_rounded,
                  ),
                  _MetricCard(
                    width: width,
                    label: 'Bank Paid',
                    value: CustomerMetalPurchaseFormatters.amount(
                      summary.bankPaid,
                    ),
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  _MetricCard(
                    width: width,
                    label: 'Card Paid',
                    value: CustomerMetalPurchaseFormatters.amount(
                      summary.cardPaid,
                    ),
                    icon: Icons.credit_card_rounded,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReportSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ReportSurface({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E0D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const accent = PurchaseEntryColors.purchaseAccent;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final TextStyle _tableHeadingStyle = GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w900,
  color: Colors.black,
);

final TextStyle _tableBodyStyle = GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: Colors.black,
);
