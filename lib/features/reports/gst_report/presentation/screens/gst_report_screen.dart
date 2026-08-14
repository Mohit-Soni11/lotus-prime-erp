import 'package:flutter/material.dart';

import '../../../../../core/feedback/app_feedback.dart';
import '../../application/gst_report_controller.dart';
import '../exports/gst_report_export_service.dart';
import '../theme/gst_report_theme.dart';
import '../widgets/gst_report_app_bar.dart';
import '../widgets/gst_report_navigation_tabs.dart';
import '../widgets/gst_report_period_selector.dart';
import '../widgets/gst_report_workspace.dart';

class GstReportScreen extends StatefulWidget {
  const GstReportScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<GstReportScreen> createState() => _GstReportScreenState();
}

class _GstReportScreenState extends State<GstReportScreen> {
  late final GstReportController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = GstReportController();
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
      data: GstReportStyles.theme,
      child: Scaffold(
        backgroundColor: GstReportColors.bodyBg,
        appBar: GstReportAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
          onRefresh: _controller.load,
          onExportSelected: _handleExportSelected,
          exportItems: _exportItems,
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
                        const _GstReportPageHeader(),
                        const SizedBox(height: 16),
                        GstReportPeriodSelector(controller: _controller),
                        const SizedBox(height: 14),
                        GstReportNavigationTabs(
                          selectedTab: _controller.selectedTab,
                          onTabSelected: _controller.selectTab,
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: GstReportWorkspace(
                            key: ValueKey(
                              '${_controller.period.startDate.toIso8601String()}-${_controller.selectedTab.name}',
                            ),
                            controller: _controller,
                            snapshot: snapshot,
                          ),
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

  Future<void> _handleExportSelected(GstReportExportAction action) async {
    final snapshot = _controller.snapshot;
    if (snapshot == null) return;

    try {
      final path = await GstReportExportService.export(snapshot, action);
      if (!mounted || path == null) return;
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: 'GST report exported successfully.',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.show(
        context,
        type: AppFeedbackType.error,
        message: 'Unable to export GST report.',
      );
    }
  }

  static const _exportItems = [
    GstReportExportMenuItem(
      action: GstReportExportAction.summaryPdf,
      label: 'GST Summary PDF',
      icon: Icons.picture_as_pdf_outlined,
    ),
    GstReportExportMenuItem(
      action: GstReportExportAction.gstr1Csv,
      label: 'GSTR-1 CSV',
      icon: Icons.table_chart_outlined,
    ),
    GstReportExportMenuItem(
      action: GstReportExportAction.gstr3bCsv,
      label: 'GSTR-3B CSV',
      icon: Icons.summarize_outlined,
    ),
    GstReportExportMenuItem(
      action: GstReportExportAction.hsnCsv,
      label: 'HSN Register CSV',
      icon: Icons.grid_on_outlined,
    ),
    GstReportExportMenuItem(
      action: GstReportExportAction.hsnPdf,
      label: 'HSN Register PDF',
      icon: Icons.picture_as_pdf_outlined,
    ),
    GstReportExportMenuItem(
      action: GstReportExportAction.invoiceLedgerCsv,
      label: 'GST Invoice Ledger CSV',
      icon: Icons.receipt_long_outlined,
    ),
    GstReportExportMenuItem(
      action: GstReportExportAction.invoiceLedgerPdf,
      label: 'GST Invoice Ledger PDF',
      icon: Icons.picture_as_pdf_outlined,
    ),
  ];
}

class _GstReportPageHeader extends StatelessWidget {
  const _GstReportPageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(GstReportStrings.moduleTitle, style: GstReportStyles.pageTitle),
        const SizedBox(height: 4),
        Text(
          'Dashboard, GSTR-1, GSTR-3B, HSN register and filing audit workspace',
          style: GstReportStyles.body,
        ),
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GstReportColors.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: GstReportColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: GstReportColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: GstReportStyles.body)),
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
      child: CircularProgressIndicator(color: GstReportColors.brandGold),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: GstReportStyles.panel(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: GstReportColors.danger,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(message, style: GstReportStyles.body),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(GstReportIcons.refresh),
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
      child: Text('No GST report data available.', style: GstReportStyles.body),
    );
  }
}
