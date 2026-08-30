import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_actions/customer_metal_purchase_ledger_actions.dart';
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
          ),
        ],
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
        return _LedgerTable(entries: controller.filteredEntries);
      case CustomerMetalPurchaseReportTab.metalSummary:
        return _MetalSummaryTable(summaries: controller.visibleMetalSummaries);
      case CustomerMetalPurchaseReportTab.sellerSummary:
        return _SellerSummaryTable(summaries: controller.sellerSummaries);
      case CustomerMetalPurchaseReportTab.pendingPayout:
        return _LedgerTable(
          entries: controller.pendingEntries,
          emptyMessage: 'No pending seller payout found for this period.',
        );
      case CustomerMetalPurchaseReportTab.paymentSummary:
        return _PaymentSummaryPanel(summary: controller.dashboardSummary);
    }
  }
}

class _LedgerTable extends StatelessWidget {
  final List<CustomerMetalPurchaseEntry> entries;
  final String emptyMessage;

  static const List<_LedgerColumn> _columns = [
    _LedgerColumn('S. No.', 66),
    _LedgerColumn('Seller', 220, flexGrow: 0.30),
    _LedgerColumn('Invoice No', 172, flexGrow: 0.20),
    _LedgerColumn('Date', 132),
    _LedgerColumn('Metal', 96),
    _LedgerColumn('Net Wt', 116),
    _LedgerColumn('Value', 118, flexGrow: 0.10),
    _LedgerColumn('Paid', 118, flexGrow: 0.10),
    _LedgerColumn('Pending', 124, flexGrow: 0.10),
    _LedgerColumn('Status', 112),
    _LedgerColumn('Photo', 82),
    _LedgerColumn('Actions', 128, flexGrow: 0.20),
  ];

  const _LedgerTable({
    required this.entries,
    this.emptyMessage = 'No customer metal purchase records found.',
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return CustomerMetalPurchaseEmptyState(message: emptyMessage);
    }

    return _ReportSurface(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(constraints.maxWidth, _baseWidth + 2);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _LedgerHeader(columns: _columns, tableWidth: tableWidth),
                  for (var index = 0; index < entries.length; index++)
                    _LedgerInteractiveRow(
                      key: ValueKey(
                        'customer-metal-purchase-ledger-row-${index + 1}',
                      ),
                      columns: _columns,
                      tableWidth: tableWidth,
                      entry: entries[index],
                      serialNo: index + 1,
                      onShowDetails: () =>
                          CustomerMetalPurchaseLedgerActions.showOptions(
                        context,
                        entries[index],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static double get _baseWidth =>
      _columns.fold(0, (total, column) => total + column.baseWidth);
}

class _LedgerColumn {
  final String label;
  final double baseWidth;
  final double flexGrow;

  const _LedgerColumn(
    this.label,
    this.baseWidth, {
    this.flexGrow = 0,
  });
}

class _LedgerHeader extends StatelessWidget {
  final List<_LedgerColumn> columns;
  final double tableWidth;

  const _LedgerHeader({
    required this.columns,
    required this.tableWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          for (final column in columns)
            _LedgerCell(
              width: _columnWidth(column),
              alignment: column.label == 'S. No.' || column.label == 'Photo'
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: Text(column.label, style: _tableHeadingStyle),
            ),
        ],
      ),
    );
  }

  double _columnWidth(_LedgerColumn column) {
    final baseWidth =
        columns.fold<double>(0, (total, item) => total + item.baseWidth);
    final extraWidth = math.max(0, tableWidth - baseWidth);
    return column.baseWidth + extraWidth * column.flexGrow;
  }
}

class _LedgerInteractiveRow extends StatefulWidget {
  final List<_LedgerColumn> columns;
  final double tableWidth;
  final CustomerMetalPurchaseEntry entry;
  final int serialNo;
  final VoidCallback onShowDetails;

  const _LedgerInteractiveRow({
    super.key,
    required this.columns,
    required this.tableWidth,
    required this.entry,
    required this.serialNo,
    required this.onShowDetails,
  });

  @override
  State<_LedgerInteractiveRow> createState() => _LedgerInteractiveRowState();
}

class _LedgerInteractiveRowState extends State<_LedgerInteractiveRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const accent = PurchaseEntryColors.purchaseAccent;
    final background =
        widget.serialNo.isEven ? const Color(0xFFFCFCFD) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onShowDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.tableWidth,
          height: 68,
          margin: const EdgeInsets.symmetric(vertical: 2),
          transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? accent.withValues(alpha: 0.70)
                  : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _LedgerCell(
                width: _columnWidth(widget.columns[0]),
                alignment: Alignment.center,
                child: Text(
                  widget.serialNo.toString(),
                  style: _tableBodyStyle,
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[1]),
                child: _TwoLineCell(
                  title: widget.entry.customerName,
                  subtitle: widget.entry.mobile ?? 'Mobile not recorded',
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[2]),
                child: Text(widget.entry.referenceNo, style: _tableBodyStyle),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[3]),
                child: Text(
                  CustomerMetalPurchaseFormatters.date(widget.entry.date),
                  style: _tableBodyStyle,
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[4]),
                child: Text(
                  widget.entry.metalType.toUpperCase(),
                  style: _tableBodyStyle,
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[5]),
                child: Text(
                  CustomerMetalPurchaseFormatters.weight(
                    widget.entry.netWeight,
                  ),
                  style: _tableBodyStyle,
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[6]),
                child: Text(
                  CustomerMetalPurchaseFormatters.amount(widget.entry.amount),
                  style: _tableBodyStyle,
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[7]),
                child: Text(
                  CustomerMetalPurchaseFormatters.amount(
                    widget.entry.paidAmount,
                  ),
                  style: _tableBodyStyle,
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[8]),
                child: Text(
                  CustomerMetalPurchaseFormatters.amount(
                    widget.entry.pendingAmount,
                  ),
                  style: _tableBodyStyle,
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[9]),
                child: _PaymentStatusBadge(entry: widget.entry),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[10]),
                alignment: Alignment.center,
                child: Icon(
                  widget.entry.hasSellerPhoto
                      ? Icons.image_rounded
                      : Icons.image_not_supported_rounded,
                  size: 18,
                  color: widget.entry.hasSellerPhoto
                      ? PurchaseEntryColors.purchaseAccent
                      : const Color(0xFF9CA3AF),
                ),
              ),
              _LedgerCell(
                width: _columnWidth(widget.columns[11]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LedgerActionIconButton(
                      tooltip: 'View PDF',
                      onPressed: () =>
                          CustomerMetalPurchaseLedgerActions.viewPdf(
                        context,
                        widget.entry,
                      ),
                      icon: const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 18,
                      ),
                    ),
                    _LedgerActionIconButton(
                      tooltip: 'View photo',
                      onPressed: widget.entry.hasSellerPhoto
                          ? () => CustomerMetalPurchaseLedgerActions.viewPhoto(
                                context,
                                widget.entry,
                              )
                          : null,
                      icon: const Icon(
                        Icons.image_rounded,
                        size: 18,
                      ),
                    ),
                    _LedgerActionIconButton(
                      tooltip: 'Print PDF',
                      onPressed: () =>
                          CustomerMetalPurchaseLedgerActions.printPdf(
                        context,
                        widget.entry,
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _columnWidth(_LedgerColumn column) {
    final baseWidth = widget.columns.fold<double>(
      0,
      (total, item) => total + item.baseWidth,
    );
    final contentWidth = math.max(0, widget.tableWidth - 3);
    final extraWidth = math.max(0, contentWidth - baseWidth);
    return column.baseWidth + extraWidth * column.flexGrow;
  }
}

class _LedgerCell extends StatelessWidget {
  final double width;
  final Widget child;
  final AlignmentGeometry alignment;

  const _LedgerCell({
    required this.width,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(alignment: alignment, child: child),
      ),
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

class _LedgerActionIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;

  const _LedgerActionIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: IconTheme(
        data: const IconThemeData(color: Colors.black, size: 18),
        child: icon,
      ),
      style: IconButton.styleFrom(
        fixedSize: const Size(32, 32),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: Colors.black,
        disabledForegroundColor: Colors.black,
        hoverColor: Colors.black.withValues(alpha: 0.06),
        highlightColor: Colors.black.withValues(alpha: 0.06),
      ),
      visualDensity: VisualDensity.compact,
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
