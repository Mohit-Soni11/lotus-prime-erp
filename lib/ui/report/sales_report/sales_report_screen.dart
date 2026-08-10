import 'package:flutter/material.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/report/sales_report/sales_report_controller.dart';
import '../../../logic/report/sales_report/sales_report_export_service.dart';
import '../../../models/reports/sales_report/sales_report_models.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';
import 'sales_report_app_bar.dart';
import 'sales_report_combined_workspace.dart';
import 'sales_report_metal_detail_screen.dart';
import 'sales_report_month_tax_filter.dart';

class SalesReportScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SalesReportScreen({super.key, this.onBack});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late final SalesReportController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = SalesReportController();
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
    return Theme(
      data: SalesReportStyles.theme,
      child: Scaffold(
        backgroundColor: SalesReportColors.bodyBg,
        appBar: SalesReportAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
          onRefresh: () => _controller.load(),
          onExportCsv: _exportCsv,
          isLoading: _controller.isLoading,
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final snapshot = _controller.snapshot;

            if (_controller.isLoading && snapshot == null) {
              return const _LoadingState();
            }

            if (_controller.errorMessage != null && snapshot == null) {
              return _ErrorState(
                message: _controller.errorMessage!,
                onRetry: _controller.load,
              );
            }

            if (snapshot == null) {
              return const _EmptyState();
            }

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
                        if (_controller.errorMessage != null) ...[
                          _InlineWarning(message: _controller.errorMessage!),
                          const SizedBox(height: 12),
                        ],
                        const _SalesReportPageHeader(),
                        const SizedBox(height: 16),
                        SalesReportMonthTaxFilter(controller: _controller),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _buildWorkspace(snapshot),
                        ),
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
        message: 'Sales report exported.',
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

  Widget _buildWorkspace(SalesReportSnapshot _) {
    final filter = _controller.filter;
    return SalesReportCombinedWorkspace(
      key: ValueKey(
        '${filter.startDate.toIso8601String()}-${filter.endDate.toIso8601String()}-${filter.taxMode.name}',
      ),
      controller: _controller,
      onMetalSelected: _openMetalLedger,
    );
  }

  void _openMetalLedger(String metalType) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => SalesReportMetalDetailScreen(
          metalType: metalType,
          initialFilter: _controller.filter.copyWith(metalType: metalType),
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _SalesReportPageHeader extends StatelessWidget {
  const _SalesReportPageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sales Report', style: SalesReportStyles.pageTitle),
        const SizedBox(height: 4),
        Text(
          'Monthly invoice ledger, item ledger and GST liability',
          style: SalesReportStyles.body,
        ),
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;

  const _InlineWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SalesReportColors.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: SalesReportColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: SalesReportColors.warning),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: SalesReportStyles.body)),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: SalesReportColors.brandGold),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No report data available.', style: SalesReportStyles.body),
    );
  }
}
