import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/report/sales_report/sales_report_controller.dart';
import '../../../logic/report/sales_report/sales_report_export_service.dart';
import '../../../models/reports/sales_report/sales_report_models.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';
import 'bill_ledger/sales_report_invoice_ledger.dart';
import 'item_ledger/sales_report_item_ledger.dart';
import 'sales_report_app_bar.dart';
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
          subtitle: 'Invoice ledger, item ledger and payment audit',
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
                          monthLabel: monthLabel,
                        ),
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
                            onBackToCards: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 16),
                          SalesReportInvoiceLedger(
                            invoices: snapshot.invoices,
                          ),
                          const SizedBox(height: 16),
                          SalesReportItemLedger(items: snapshot.items),
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

  String _metalTitle(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Metal';
    return normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
  }
}

class _MetalLedgerHeader extends StatelessWidget {
  final String metalTitle;
  final String monthLabel;

  const _MetalLedgerHeader({
    required this.metalTitle,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$metalTitle Sales Ledger',
                style: SalesReportStyles.pageTitle,
              ),
              const SizedBox(height: 4),
              Text(
                'Monthly invoice, stock deduction, making and profit movement',
                style: SalesReportStyles.body,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SalesReportColors.goldGradientStart.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SalesReportColors.brandGold.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                SalesReportIcons.calendar,
                size: 12,
                color: SalesReportColors.brandGold,
              ),
              const SizedBox(width: 6),
              Text(
                monthLabel,
                style: SalesReportStyles.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: SalesReportColors.brandGold,
                ),
              ),
            ],
          ),
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
