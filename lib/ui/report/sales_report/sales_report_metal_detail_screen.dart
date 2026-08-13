import 'dart:typed_data';

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
import 'sales_report_pdf_preview_dialog.dart';
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
          onExportSelected: _handleExportSelected,
          exportItems: _metalExportItems,
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
                            items: gradeItems,
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

  Future<void> _handleExportSelected(SalesReportExportAction action) async {
    final snapshot = _controller.snapshot;
    if (snapshot == null) return;

    final metalTitle = _metalTitle(widget.metalType);
    final grade = _effectiveSelectedGrade(snapshot.items);
    final gradeItems = _itemsForGrade(snapshot.items, grade);
    final gradeInvoices = _invoicesForItems(
      snapshot.invoices,
      gradeItems,
      grade,
    );
    final filePrefix = '${metalTitle.toLowerCase()}-sales-ledger';

    late final Future<String?> export;
    late final String successMessage;
    switch (action) {
      case SalesReportExportAction.completePreview:
        await _showPdfPreview(
          title: '$metalTitle Sales Ledger Preview',
          subtitle: 'Metal sales, grade-wise, invoice and item ledger',
          fileName: '$filePrefix-preview.pdf',
          buildBytes: () =>
              SalesReportExportService.buildMetalCompletePreviewPdfBytes(
            snapshot,
            metalTitle: metalTitle,
          ),
        );
        return;
      case SalesReportExportAction.completePdf:
        export = SalesReportExportService.exportMetalCompletePdf(
          snapshot,
          metalTitle: metalTitle,
          filePrefix: filePrefix,
        );
        successMessage = '$metalTitle sales ledger PDF downloaded.';
      case SalesReportExportAction.completeCsv:
        export = SalesReportExportService.exportMetalCompleteCsv(
          snapshot,
          metalTitle: metalTitle,
          filePrefix: filePrefix,
        );
        successMessage = '$metalTitle sales ledger CSV downloaded.';
      case SalesReportExportAction.gradeWisePreview:
        await _showPdfPreview(
          title: '$metalTitle Grade-wise Preview',
          subtitle: 'Grade and purity-wise $metalTitle sales summary',
          fileName: '$filePrefix-grade-wise-preview.pdf',
          buildBytes: () =>
              SalesReportExportService.buildGradeWisePreviewPdfBytes(
            snapshot,
            metalTitle: metalTitle,
          ),
        );
        return;
      case SalesReportExportAction.gradeWisePdf:
        export = SalesReportExportService.exportGradeWisePdf(
          snapshot,
          metalTitle: metalTitle,
        );
        successMessage = '$metalTitle grade-wise report PDF downloaded.';
      case SalesReportExportAction.invoiceLedgerPreview:
        await _showPdfPreview(
          title: '$metalTitle Invoice Ledger Preview',
          subtitle: 'Selected grade bill-wise sales and tax audit',
          fileName: '$filePrefix-invoice-ledger-preview.pdf',
          buildBytes: () =>
              SalesReportExportService.buildInvoiceLedgerPreviewPdfBytes(
            snapshot,
            invoices: gradeInvoices,
            items: gradeItems,
            reportTitle: '$metalTitle Invoice Ledger',
          ),
        );
        return;
      case SalesReportExportAction.invoiceLedgerPdf:
        export = SalesReportExportService.exportInvoiceLedgerPdf(
          snapshot,
          invoices: gradeInvoices,
          items: gradeItems,
          reportTitle: '$metalTitle Invoice Ledger',
          filePrefix: '$filePrefix-invoice-ledger',
        );
        successMessage = '$metalTitle invoice ledger PDF downloaded.';
      case SalesReportExportAction.itemLedgerPreview:
        await _showPdfPreview(
          title: '$metalTitle Item Ledger Preview',
          subtitle: 'Selected grade item-wise HUID, purity and weight audit',
          fileName: '$filePrefix-item-ledger-preview.pdf',
          buildBytes: () =>
              SalesReportExportService.buildItemLedgerPreviewPdfBytes(
            snapshot,
            items: gradeItems,
            reportTitle: '$metalTitle Item Ledger',
          ),
        );
        return;
      case SalesReportExportAction.itemLedgerPdf:
        export = SalesReportExportService.exportItemLedgerPdf(
          snapshot,
          items: gradeItems,
          reportTitle: '$metalTitle Item Ledger',
          filePrefix: '$filePrefix-item-ledger',
        );
        successMessage = '$metalTitle item ledger PDF downloaded.';
      case SalesReportExportAction.invoiceLedgerCsv:
        export = SalesReportExportService.exportInvoiceLedgerCsv(
          snapshot,
          invoices: gradeInvoices,
          items: gradeItems,
          filePrefix: '$filePrefix-invoice-ledger',
        );
        successMessage = '$metalTitle invoice ledger CSV downloaded.';
      case SalesReportExportAction.itemLedgerCsv:
        export = SalesReportExportService.exportItemLedgerCsv(
          snapshot,
          items: gradeItems,
          filePrefix: '$filePrefix-item-ledger',
        );
        successMessage = '$metalTitle item ledger CSV downloaded.';
      case SalesReportExportAction.completeExcel:
        export = SalesReportExportService.exportMetalCompleteExcel(
          snapshot,
          metalTitle: metalTitle,
          filePrefix: filePrefix,
        );
        successMessage = '$metalTitle sales ledger Excel downloaded.';
      case SalesReportExportAction.gstLiabilityPreview:
      case SalesReportExportAction.gstLiabilityPdf:
        return;
    }

    try {
      final path = await export;
      if (!mounted || path == null) return;
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: successMessage,
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

  Future<void> _showPdfPreview({
    required String title,
    required String subtitle,
    required String fileName,
    required Future<Uint8List> Function() buildBytes,
  }) {
    return SalesReportPdfPreviewDialog.show(
      context,
      title: title,
      subtitle: subtitle,
      fileName: fileName,
      buildBytes: buildBytes,
    );
  }

  static const _metalExportItems = [
    SalesReportExportMenuItem(
      action: SalesReportExportAction.completePdf,
      label: 'Metal Sales Ledger PDF',
      icon: Icons.picture_as_pdf_outlined,
    ),
    SalesReportExportMenuItem(
      action: SalesReportExportAction.completeCsv,
      label: 'Metal Sales Ledger CSV',
      icon: Icons.table_chart_outlined,
    ),
    SalesReportExportMenuItem(
      action: SalesReportExportAction.gradeWisePdf,
      label: 'Grade-wise Sales Report PDF',
      icon: Icons.workspace_premium_outlined,
    ),
    SalesReportExportMenuItem(
      action: SalesReportExportAction.invoiceLedgerPdf,
      label: 'Metal Invoice Ledger PDF',
      icon: Icons.picture_as_pdf_outlined,
    ),
    SalesReportExportMenuItem(
      action: SalesReportExportAction.itemLedgerPdf,
      label: 'Metal Item Ledger PDF',
      icon: Icons.picture_as_pdf_outlined,
    ),
    SalesReportExportMenuItem(
      action: SalesReportExportAction.invoiceLedgerCsv,
      label: 'Metal Invoice Ledger CSV',
      icon: Icons.receipt_long_outlined,
    ),
    SalesReportExportMenuItem(
      action: SalesReportExportAction.itemLedgerCsv,
      label: 'Metal Item Ledger CSV',
      icon: Icons.inventory_2_outlined,
    ),
    SalesReportExportMenuItem(
      action: SalesReportExportAction.completeExcel,
      label: 'Metal Sales Ledger Excel',
      icon: Icons.grid_on_outlined,
    ),
  ];

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
