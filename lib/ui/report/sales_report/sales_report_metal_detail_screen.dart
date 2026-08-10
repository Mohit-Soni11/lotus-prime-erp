import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/report/sales_report/sales_report_controller.dart';
import '../../../logic/report/sales_report/sales_report_export_service.dart';
import '../../../logic/report/sales_report/sales_report_invoice_scope.dart';
import '../../../models/reports/sales_report/sales_report_models.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';
import 'bill_ledger/sales_report_invoice_ledger.dart';
import 'item_ledger/sales_report_item_ledger.dart';
import 'sales_report_app_bar.dart';
import 'sales_report_month_tax_filter.dart';
import 'summary/sales_report_grade_summary.dart';
import 'summary/sales_report_metal_cards.dart';

class SalesReportMetalDetailScreen extends StatefulWidget {
  final String metalType;
  final SalesReportFilter initialFilter;

  const SalesReportMetalDetailScreen({
    super.key,
    required this.metalType,
    required this.initialFilter,
  });

  @override
  State<SalesReportMetalDetailScreen> createState() =>
      _SalesReportMetalDetailScreenState();
}

class _SalesReportMetalDetailScreenState
    extends State<SalesReportMetalDetailScreen> {
  late final SalesReportController _controller;
  final ScrollController _scrollController = ScrollController();
  String _selectedGrade = allSalesReportGrades;

  @override
  void initState() {
    super.initState();
    _controller = SalesReportController(initialFilter: widget.initialFilter);
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final metalTitle = _metalTitle(widget.metalType);

    return Theme(
      data: SalesReportStyles.theme,
      child: Scaffold(
        backgroundColor: SalesReportColors.bodyBg,
        appBar: SalesReportAppBar(
          title: '$metalTitle Sales Report',
          subtitle: 'Invoice ledger, item ledger and tax audit',
          onBack: () => Navigator.of(context).pop(),
          onRefresh: () => _controller.load(),
          onExportCsv: _exportCsv,
          isLoading: _controller.isLoading,
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final snapshot = _controller.snapshot;

            if (_controller.isLoading && snapshot == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: SalesReportColors.brandGold,
                ),
              );
            }

            if (_controller.errorMessage != null && snapshot == null) {
              return _DetailErrorState(
                message: _controller.errorMessage!,
                onRetry: _controller.load,
              );
            }

            if (snapshot == null) {
              return const SizedBox.shrink();
            }

            final monthLabel = DateFormat('MMMM yyyy').format(
              _controller.filter.startDate,
            );
            final metalSummary = _summaryFor(snapshot, widget.metalType);
            final effectiveGrade = _effectiveSelectedGrade(snapshot.items);
            final gradeItems = _itemsForGrade(snapshot.items, effectiveGrade);
            final gradeInvoices = _invoicesForItems(
              snapshot.invoices,
              gradeItems,
              effectiveGrade,
            );

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1880),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MetalLedgerHeader(
                          metalTitle: metalTitle,
                        ),
                        const SizedBox(height: 16),
                        SalesReportMonthTaxFilter(controller: _controller),
                        const SizedBox(height: 24),
                        if (metalSummary == null)
                          _NoMetalSalesState(
                            metalTitle: metalTitle,
                            monthLabel: monthLabel,
                          )
                        else ...[
                          SalesReportMetalDetailPanel(
                            metal: metalSummary,
                            periodLabel: monthLabel,
                            recordedGstAmount: salesReportRecordedGstForItems(
                              invoices: snapshot.invoices,
                              items: snapshot.items,
                            ),
                            projectedGstAmount:
                                salesReportProjectedGstForItems(snapshot.items),
                            onBackToCards: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 16),
                          SalesReportGradeSummaryPanel(
                            invoices: snapshot.invoices,
                            items: snapshot.items,
                            selectedGrade: effectiveGrade,
                            onGradeSelected: (grade) {
                              setState(() => _selectedGrade = grade);
                            },
                          ),
                          const SizedBox(height: 16),
                          SalesReportInvoiceLedger(
                            invoices: gradeInvoices,
                          ),
                          const SizedBox(height: 16),
                          SalesReportItemLedger(items: gradeItems),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final snapshot = _controller.snapshot;
    if (snapshot == null) return;

    try {
      final path = await SalesReportExportService.exportCsv(snapshot);
      if (!mounted || path == null) return;
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: '${_metalTitle(widget.metalType)} sales report exported.',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.show(
        context,
        type: AppFeedbackType.error,
        message: 'Unable to export sales report.',
      );
    }
  }

  SalesReportMetalSummary? _summaryFor(
    SalesReportSnapshot snapshot,
    String metalType,
  ) {
    final normalized = metalType.trim().toUpperCase();
    for (final metal in snapshot.metals) {
      if (metal.metalType.trim().toUpperCase() == normalized) {
        return metal;
      }
    }
    return null;
  }

  String _effectiveSelectedGrade(List<SalesReportItemRow> items) {
    if (_selectedGrade == allSalesReportGrades) return allSalesReportGrades;
    final selected = _selectedGrade.trim().toUpperCase();
    final exists = items.any(
      (item) => _gradeLabel(item.purity) == selected,
    );
    return exists ? selected : allSalesReportGrades;
  }

  List<SalesReportItemRow> _itemsForGrade(
    List<SalesReportItemRow> items,
    String grade,
  ) {
    if (grade == allSalesReportGrades) return items;
    return items
        .where((item) => _gradeLabel(item.purity) == grade)
        .toList(growable: false);
  }

  List<SalesReportInvoiceRow> _invoicesForItems(
    List<SalesReportInvoiceRow> invoices,
    List<SalesReportItemRow> items,
    String grade,
  ) {
    if (items.isEmpty) return const [];
    if (grade != allSalesReportGrades) {
      return scopeSalesReportInvoicesToItems(
        invoices: invoices,
        items: items,
      );
    }
    final billIds = items.map((item) => item.billId).toSet();
    return invoices
        .where((invoice) => billIds.contains(invoice.billId))
        .toList(growable: false);
  }

  String _gradeLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'UNSPECIFIED';
    return trimmed.toUpperCase();
  }

  String _metalTitle(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Metal';
    return normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
  }
}

class _MetalLedgerHeader extends StatelessWidget {
  final String metalTitle;

  const _MetalLedgerHeader({
    required this.metalTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$metalTitle Sales Ledger',
          style: SalesReportStyles.pageTitle,
        ),
        const SizedBox(height: 4),
        Text(
          'Monthly invoice, tax, making and item movement',
          style: SalesReportStyles.body,
        ),
      ],
    );
  }
}

class _NoMetalSalesState extends StatelessWidget {
  final String metalTitle;
  final String monthLabel;

  const _NoMetalSalesState({
    required this.metalTitle,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: SalesReportStyles.panel(),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: SalesReportColors.brandGold,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$monthLabel mein $metalTitle sales record available nahi hai.',
              style: SalesReportStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: SalesReportColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: SalesReportStyles.panel(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC63F3F),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(message, style: SalesReportStyles.body),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(SalesReportIcons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
