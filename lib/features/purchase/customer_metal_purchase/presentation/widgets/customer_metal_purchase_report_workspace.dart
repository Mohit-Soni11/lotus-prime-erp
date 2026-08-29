import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/exports/customer_metal_purchase_report_print_service.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_filters/customer_metal_purchase_report_filter_bar.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_metal_cards/customer_metal_purchase_metal_card_grid.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_summary/customer_metal_purchase_summary_band.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseReportWorkspace extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;
  final AnimationController animationController;
  final ValueChanged<CustomerMetalPurchaseEntry> onOpenVoucher;

  const CustomerMetalPurchaseReportWorkspace({
    super.key,
    required this.controller,
    required this.animationController,
    required this.onOpenVoucher,
  });

  @override
  Widget build(BuildContext context) {
    final dashboard = controller.dashboardSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerMetalPurchaseReportFilterBar(controller: controller),
          const SizedBox(height: 16),
          CustomerMetalPurchaseMetalCardGrid(
            periodLabel: controller.periodLabel,
            summaries: controller.visibleMetalSummaries,
            selectedMetal: controller.selectedMetal,
            animationController: animationController,
            onMetalSelected: controller.selectMetal,
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
            onOpenVoucher: onOpenVoucher,
          ),
        ],
      ),
    );
  }
}

class CustomerMetalPurchaseReportTabs extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseReportTabs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in CustomerMetalPurchaseReportTab.values)
          _TabButton(
            label: tab.label,
            selected: controller.selectedTab == tab,
            onTap: () => controller.selectTab(tab),
          ),
      ],
    );
  }
}

class CustomerMetalPurchaseReportCommandStrip extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseReportCommandStrip({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final printButton = _ReportActionButton(
          icon: Icons.print_rounded,
          label: 'Print Report',
          onPressed: controller.filteredEntries.isEmpty
              ? null
              : () => _printReport(context),
        );

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomerMetalPurchaseReportTabs(controller: controller),
              const SizedBox(height: 12),
              printButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomerMetalPurchaseReportTabs(controller: controller),
            ),
            const SizedBox(width: 12),
            printButton,
          ],
        );
      },
    );
  }

  Future<void> _printReport(BuildContext context) async {
    try {
      await CustomerMetalPurchaseReportPrintService.printReport(
        periodLabel: controller.periodLabel,
        dashboard: controller.dashboardSummary,
        metalSummaries: controller.visibleMetalSummaries,
        entries: controller.filteredEntries,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report print failed: $error')),
      );
    }
  }
}

class CustomerMetalPurchaseReportBody extends StatelessWidget {
  final CustomerMetalPurchaseLedgerController controller;
  final ValueChanged<CustomerMetalPurchaseEntry> onOpenVoucher;

  const CustomerMetalPurchaseReportBody({
    super.key,
    required this.controller,
    required this.onOpenVoucher,
  });

  @override
  Widget build(BuildContext context) {
    switch (controller.selectedTab) {
      case CustomerMetalPurchaseReportTab.ledger:
        return _LedgerTable(
          entries: controller.filteredEntries,
          onOpenVoucher: onOpenVoucher,
        );
      case CustomerMetalPurchaseReportTab.metalSummary:
        return _MetalSummaryTable(summaries: controller.visibleMetalSummaries);
      case CustomerMetalPurchaseReportTab.sellerSummary:
        return _SellerSummaryTable(summaries: controller.sellerSummaries);
      case CustomerMetalPurchaseReportTab.pendingPayout:
        return _LedgerTable(
          entries: controller.pendingEntries,
          onOpenVoucher: onOpenVoucher,
          emptyMessage: 'No pending seller payout found for this period.',
        );
      case CustomerMetalPurchaseReportTab.paymentSummary:
        return _PaymentSummaryPanel(summary: controller.dashboardSummary);
    }
  }
}

class _LedgerTable extends StatelessWidget {
  final List<CustomerMetalPurchaseEntry> entries;
  final ValueChanged<CustomerMetalPurchaseEntry> onOpenVoucher;
  final String emptyMessage;

  const _LedgerTable({
    required this.entries,
    required this.onOpenVoucher,
    this.emptyMessage = 'No customer metal purchase records found.',
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return CustomerMetalPurchaseEmptyState(message: emptyMessage);
    }

    return _ReportSurface(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 68,
          columnSpacing: 24,
          headingTextStyle: _tableHeadingStyle,
          dataTextStyle: _tableBodyStyle,
          columns: const [
            DataColumn(label: Text('S. No.')),
            DataColumn(label: Text('Seller')),
            DataColumn(label: Text('Invoice No')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Metal')),
            DataColumn(label: Text('Net Wt')),
            DataColumn(label: Text('Fine Wt')),
            DataColumn(label: Text('Value')),
            DataColumn(label: Text('Paid')),
            DataColumn(label: Text('Pending')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Photo')),
            DataColumn(label: Text('Actions')),
          ],
          rows: [
            for (var index = 0; index < entries.length; index++)
              _ledgerRow(context, entries[index], index + 1),
          ],
        ),
      ),
    );
  }

  DataRow _ledgerRow(
    BuildContext context,
    CustomerMetalPurchaseEntry entry,
    int serialNo,
  ) {
    return DataRow(
      onSelectChanged: (_) => _showEntryDetails(context, entry),
      cells: [
        DataCell(Text(serialNo.toString())),
        DataCell(
          _TwoLineCell(
            title: entry.customerName,
            subtitle: entry.mobile ?? 'Mobile not recorded',
          ),
        ),
        DataCell(Text(entry.referenceNo)),
        DataCell(Text(CustomerMetalPurchaseFormatters.date(entry.date))),
        DataCell(Text(entry.metalType.toUpperCase())),
        DataCell(Text(CustomerMetalPurchaseFormatters.weight(entry.netWeight))),
        DataCell(
            Text(CustomerMetalPurchaseFormatters.weight(entry.fineWeight))),
        DataCell(Text(CustomerMetalPurchaseFormatters.amount(entry.amount))),
        DataCell(
          Text(CustomerMetalPurchaseFormatters.amount(entry.paidAmount)),
        ),
        DataCell(
          Text(CustomerMetalPurchaseFormatters.amount(entry.pendingAmount)),
        ),
        DataCell(_PaymentStatusBadge(entry: entry)),
        DataCell(
          Icon(
            entry.hasSellerPhoto
                ? Icons.image_rounded
                : Icons.image_not_supported_rounded,
            size: 18,
            color: entry.hasSellerPhoto
                ? PurchaseEntryColors.purchaseAccent
                : const Color(0xFF9CA3AF),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Open voucher',
                onPressed: () => onOpenVoucher(entry),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
              ),
              IconButton(
                tooltip: 'View details',
                onPressed: () => _showEntryDetails(context, entry),
                icon: const Icon(Icons.visibility_rounded, size: 18),
              ),
              IconButton(
                tooltip: entry.hasSellerPhoto ? 'View photo' : 'No photo',
                onPressed: entry.hasSellerPhoto
                    ? () => _showPhotoPreview(context, entry)
                    : null,
                icon: const Icon(Icons.photo_camera_back_rounded, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetalSummaryTable extends StatelessWidget {
  final Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
      summaries;

  const _MetalSummaryTable({required this.summaries});

  @override
  Widget build(BuildContext context) {
    return _ReportSurface(
      padding: EdgeInsets.zero,
      child: DataTable(
        headingRowHeight: 48,
        columnSpacing: 30,
        headingTextStyle: _tableHeadingStyle,
        dataTextStyle: _tableBodyStyle,
        columns: const [
          DataColumn(label: Text('Metal')),
          DataColumn(label: Text('Fine Weight')),
          DataColumn(label: Text('Value')),
          DataColumn(label: Text('Paid')),
          DataColumn(label: Text('Pending')),
          DataColumn(label: Text('Entries')),
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
                  Text(CustomerMetalPurchaseFormatters.amount(
                    entry.value.pendingAmount,
                  )),
                ),
                DataCell(Text(entry.value.entryCount.toString())),
                DataCell(Text(entry.value.customerCount.toString())),
              ],
            ),
        ],
      ),
    );
  }
}

class _SellerSummaryTable extends StatelessWidget {
  final List<CustomerMetalPurchaseSellerSummary> summaries;

  const _SellerSummaryTable({required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const CustomerMetalPurchaseEmptyState(
        message: 'No seller summary found for this period.',
      );
    }

    return _ReportSurface(
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
                    Text(CustomerMetalPurchaseFormatters.amount(
                      summary.pendingAmount,
                    )),
                  ),
                  DataCell(Text(summary.voucherCount.toString())),
                  DataCell(Text(summary.entryCount.toString())),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSummaryPanel extends StatelessWidget {
  final CustomerMetalPurchaseDashboardSummary summary;

  const _PaymentSummaryPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _ReportSurface(
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
                value: CustomerMetalPurchaseFormatters.amount(summary.cashPaid),
                icon: Icons.payments_rounded,
              ),
              _MetricCard(
                width: width,
                label: 'UPI Paid',
                value: CustomerMetalPurchaseFormatters.amount(summary.upiPaid),
                icon: Icons.account_balance_rounded,
              ),
              _MetricCard(
                width: width,
                label: 'Bank Paid',
                value: CustomerMetalPurchaseFormatters.amount(summary.bankPaid),
                icon: Icons.account_balance_wallet_rounded,
              ),
              _MetricCard(
                width: width,
                label: 'Card Paid',
                value: CustomerMetalPurchaseFormatters.amount(summary.cardPaid),
                icon: Icons.credit_card_rounded,
              ),
            ],
          );
        },
      ),
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

class _ReportActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ReportActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(168, 42),
        backgroundColor: PurchaseEntryColors.purchaseAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE5E7EB),
        disabledForegroundColor: const Color(0xFF0B1220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? PurchaseEntryColors.purchaseAccent
                  : const Color(0xFFE5E0D8),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: PurchaseEntryColors.purchaseAccent
                          .withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: selected
                  ? PurchaseEntryColors.purchaseAccent
                  : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}

class _TwoLineCell extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TwoLineCell({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _tableBodyStyle.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _tableBodyStyle.copyWith(
              fontSize: 11,
              color: const Color(0xFF0B1220),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;

  const _PaymentStatusBadge({required this.entry});

  @override
  Widget build(BuildContext context) {
    final status = entry.resolvedPaymentStatus.toUpperCase();
    final color = status == 'PAID'
        ? const Color(0xFF047857)
        : status == 'PARTIAL'
            ? const Color(0xFFB45309)
            : status == 'RETURNED'
                ? const Color(0xFF0B1220)
                : const Color(0xFFB91C1C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

Future<void> _showEntryDetails(
  BuildContext context,
  CustomerMetalPurchaseEntry entry,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.referenceNo,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 3 : 2;
                    const spacing = 12.0;
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _DetailTile(
                          width: width,
                          label: 'Seller',
                          value: entry.customerName,
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Mobile',
                          value: entry.mobile ?? 'Not recorded',
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Date',
                          value:
                              CustomerMetalPurchaseFormatters.date(entry.date),
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Metal',
                          value: entry.metalType,
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Item',
                          value: entry.itemDescription.isEmpty
                              ? entry.metalType
                              : entry.itemDescription,
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Payment Mode',
                          value: entry.paymentModeLabel,
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Net Weight',
                          value: CustomerMetalPurchaseFormatters.weight(
                            entry.netWeight,
                          ),
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Fine Weight',
                          value: CustomerMetalPurchaseFormatters.weight(
                            entry.fineWeight,
                          ),
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Value',
                          value: CustomerMetalPurchaseFormatters.amount(
                            entry.amount,
                          ),
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Paid',
                          value: CustomerMetalPurchaseFormatters.amount(
                            entry.paidAmount,
                          ),
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Pending',
                          value: CustomerMetalPurchaseFormatters.amount(
                            entry.pendingAmount,
                          ),
                        ),
                        _DetailTile(
                          width: width,
                          label: 'Commitment Date',
                          value: entry.commitmentDate == null
                              ? 'Not required'
                              : CustomerMetalPurchaseFormatters.date(
                                  entry.commitmentDate!,
                                ),
                        ),
                      ],
                    );
                  },
                ),
                if (entry.hasSellerPhoto) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _showPhotoPreview(context, entry),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('View Seller Photo'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DetailTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _DetailTile({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E0D8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0B1220),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showPhotoPreview(
  BuildContext context,
  CustomerMetalPurchaseEntry entry,
) {
  final path = entry.sellerPhotoPath?.trim();
  if (path == null || path.isEmpty) {
    return Future.value();
  }
  final file = File(path);

  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.customerName} Photo Proof',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _downloadPhoto(context, file),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download'),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: file.existsSync()
                        ? InteractiveViewer(
                            child: Image.file(file, fit: BoxFit.contain),
                          )
                        : const CustomerMetalPurchaseEmptyState(
                            message: 'Seller photo file is missing.',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _downloadPhoto(BuildContext context, File source) async {
  if (!source.existsSync()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo file is missing.')),
    );
    return;
  }
  final downloads = await getDownloadsDirectory();
  if (!context.mounted) {
    return;
  }
  if (downloads == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloads folder was not found.')),
    );
    return;
  }
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final target = File('${downloads.path}\\seller-photo-$timestamp.jpg');
  await source.copy(target.path);
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Photo saved to ${target.path}')),
  );
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
