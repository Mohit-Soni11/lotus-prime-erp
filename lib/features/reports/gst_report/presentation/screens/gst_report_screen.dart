import 'package:flutter/material.dart';

import '../../../../../core/feedback/app_feedback.dart';
import '../../application/gst_report_controller.dart';
import '../../application/gst_report_segment_projector.dart';
import '../../domain/gst_filing_period.dart';
import '../../domain/gstr1_filing_models.dart';
import '../../domain/gst_report_models.dart';
import '../exports/gst_report_export_service.dart';
import '../exports/gst_report_portal_pack_builder.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import '../widgets/gst_filing_completion_dialog.dart';
import '../widgets/gst_report_app_bar.dart';
import '../widgets/gst_report_navigation_tabs.dart';
import '../widgets/gst_report_period_selector.dart';
import '../widgets/gst_report_workspace.dart';

class GstReportScreen extends StatefulWidget {
  const GstReportScreen({
    super.key,
    this.onBack,
    this.segment,
    this.initialPeriod,
    this.initialTab = GstReportTab.dashboard,
  });

  final VoidCallback? onBack;
  final GstFilingSegment? segment;
  final GstReportPeriod? initialPeriod;
  final GstReportTab initialTab;

  @override
  State<GstReportScreen> createState() => _GstReportScreenState();
}

class _GstReportScreenState extends State<GstReportScreen> {
  late final GstReportController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = GstReportController(
      initialPeriod: widget.initialPeriod,
      initialTab: widget.initialTab,
    );
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
    final rawExportSnapshot = _controller.snapshot;
    final segmentExportSnapshot = _segmentExportSnapshot;

    return Theme(
      data: GstReportStyles.theme,
      child: Scaffold(
        backgroundColor: GstReportColors.bodyBg,
        appBar: GstReportAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
          onExportSelected: _handleExportSelected,
          exportItems: _exportItemsFor(
            widget.segment,
            rawExportSnapshot,
            segmentExportSnapshot,
          ),
          isLoading: _controller.isLoading,
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final rawSnapshot = _controller.snapshot;

            if (_controller.isLoading && rawSnapshot == null) {
              return const _LoadingState();
            }

            if (_controller.errorMessage != null && rawSnapshot == null) {
              return _ErrorState(
                message: _controller.errorMessage!,
                onRetry: _controller.load,
              );
            }

            if (rawSnapshot == null) {
              return const _EmptyState();
            }

            final snapshot = widget.segment == null
                ? rawSnapshot
                : GstReportSegmentProjector.project(
                    rawSnapshot,
                    widget.segment!,
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
                        if (_controller.errorMessage != null) ...[
                          _InlineWarning(message: _controller.errorMessage!),
                          const SizedBox(height: 12),
                        ],
                        _GstReportPageHeader(segment: widget.segment),
                        if (widget.segment != null) ...[
                          const SizedBox(height: 12),
                          _SegmentFilingControlBar(
                            segment: widget.segment!,
                            snapshot: snapshot,
                            controller: _controller,
                            onComplete: () => _confirmSegmentCompletion(
                              widget.segment!,
                              snapshot,
                            ),
                          ),
                        ],
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
                            segment: widget.segment,
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
    final rawSnapshot = _controller.snapshot;
    if (rawSnapshot == null) return;
    final snapshot = _usesFullPeriodSnapshot(action) || widget.segment == null
        ? rawSnapshot
        : GstReportSegmentProjector.project(rawSnapshot, widget.segment!);

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

  GstReportSnapshot? get _segmentExportSnapshot {
    final rawSnapshot = _controller.snapshot;
    if (rawSnapshot == null) return null;
    if (widget.segment == null) return rawSnapshot;
    return GstReportSegmentProjector.project(rawSnapshot, widget.segment!);
  }

  Future<void> _confirmSegmentCompletion(
    GstFilingSegment segment,
    GstReportSnapshot snapshot,
  ) async {
    if (!_controller.canCompleteSelectedPeriod) return;
    final confirmed = await GstFilingCompletionDialog.show(
      context: context,
      segment: segment,
      snapshot: snapshot,
      filing: GstFilingPeriod.fromMonth(_controller.period.month),
    );
    if (!confirmed || !mounted) return;
    await _controller.completeSegmentFiling(segment);
  }

  static List<GstReportExportMenuItem> _exportItemsFor(
    GstFilingSegment? segment,
    GstReportSnapshot? rawSnapshot,
    GstReportSnapshot? segmentSnapshot,
  ) {
    if (rawSnapshot == null || segmentSnapshot == null) return const [];

    switch (segment) {
      case GstFilingSegment.b2b:
        return _b2bExportItems(segmentSnapshot);
      case GstFilingSegment.b2c:
        return _b2cExportItems(segmentSnapshot);
      case null:
        return _completeExportItems(rawSnapshot);
    }
  }

  static List<GstReportExportMenuItem> _completeExportItems(
    GstReportSnapshot snapshot,
  ) {
    final filing = Gstr1FilingSnapshot.fromReport(snapshot);
    final items = <GstReportExportMenuItem>[];

    if (_hasPortalUploadDocuments(snapshot, null)) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.portalUtilityPackZip,
          label: 'GSTR-1 Upload CSV Pack',
          subtitle: 'Only non-empty official Offline Tool section files',
          section: 'GST Portal Upload',
          icon: Icons.folder_zip_outlined,
          primary: true,
        ),
      );
    }
    if (filing.b2bInvoices.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1B2bCsv,
          label: 'GSTR-1 B2B Invoice CSV',
          subtitle: 'Registered customer invoices for IFF/GSTR-1',
          section: 'GSTR-1 Section CSV',
          icon: Icons.business_center_outlined,
        ),
      );
    }
    if (filing.b2cLargeInvoices.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1B2clCsv,
          label: 'GSTR-1 B2CL CSV',
          subtitle: 'Large interstate B2C invoices only',
          section: 'GSTR-1 Section CSV',
          icon: Icons.storefront_outlined,
        ),
      );
    }
    if (filing.b2cSmallSummary.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1B2csCsv,
          label: 'GSTR-1 B2CS CSV',
          subtitle: 'Small B2C consolidated summary only',
          section: 'GSTR-1 Section CSV',
          icon: Icons.storefront_outlined,
        ),
      );
    }
    if (filing.hsnB2bSummary.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1HsnB2bCsv,
          label: 'HSN Table 12 B2B CSV',
          subtitle: 'HSN summary for registered customer sales',
          section: 'GSTR-1 Section CSV',
          icon: Icons.grid_view_outlined,
        ),
      );
    }
    if (filing.hsnB2cSummary.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1HsnB2cCsv,
          label: 'HSN Table 12 B2C CSV',
          subtitle: 'HSN summary for retail customer sales',
          section: 'GSTR-1 Section CSV',
          icon: Icons.grid_on_outlined,
        ),
      );
    }
    if (filing.documentSummary.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1DocumentsCsv,
          label: 'Document Summary CSV',
          subtitle: 'Table 13 invoice series count for the return',
          section: 'GSTR-1 Section CSV',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    items.addAll(
      const [
        GstReportExportMenuItem(
          action: GstReportExportAction.gstr3bCsv,
          label: 'GSTR-3B Entry Reference CSV',
          subtitle: 'Manual portal values; this is not an upload file',
          section: 'GSTR-3B Manual Entry',
          icon: Icons.summarize_outlined,
        ),
        GstReportExportMenuItem(
          action: GstReportExportAction.summaryPdf,
          label: 'GST Summary PDF',
          subtitle: 'Readable filing review for records',
          section: 'Audit / Review',
          icon: Icons.picture_as_pdf_outlined,
        ),
        GstReportExportMenuItem(
          action: GstReportExportAction.gstr1Csv,
          label: 'GSTR-1 Review CSV',
          subtitle: 'Complete outward supply working sheet',
          section: 'Audit / Review',
          icon: Icons.table_chart_outlined,
        ),
        GstReportExportMenuItem(
          action: GstReportExportAction.hsnCsv,
          label: 'Complete HSN Working CSV',
          subtitle: 'Internal B2B and B2C HSN register',
          section: 'Audit / Review',
          icon: Icons.grid_on_outlined,
        ),
        GstReportExportMenuItem(
          action: GstReportExportAction.hsnPdf,
          label: 'Complete HSN Working PDF',
          subtitle: 'Printable HSN register for records',
          section: 'Audit / Review',
          icon: Icons.picture_as_pdf_outlined,
        ),
        GstReportExportMenuItem(
          action: GstReportExportAction.invoiceLedgerCsv,
          label: 'GST Invoice Ledger CSV',
          subtitle: 'Invoice-wise GST breakup and audit reference',
          section: 'Audit / Review',
          icon: Icons.receipt_long_outlined,
        ),
        GstReportExportMenuItem(
          action: GstReportExportAction.invoiceLedgerPdf,
          label: 'GST Invoice Ledger PDF',
          subtitle: 'Printable invoice-wise GST ledger',
          section: 'Audit / Review',
          icon: Icons.picture_as_pdf_outlined,
        ),
      ],
    );
    return items;
  }

  static List<GstReportExportMenuItem> _b2bExportItems(
    GstReportSnapshot snapshot,
  ) {
    final filing = Gstr1FilingSnapshot.fromReport(snapshot);
    final items = <GstReportExportMenuItem>[];
    if (_hasPortalUploadDocuments(snapshot, GstFilingSegment.b2b)) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.b2bPortalUtilityPackZip,
          label: 'B2B Upload CSV Pack',
          subtitle: 'Official B2B and HSN B2B section files only',
          section: 'GST Portal Upload',
          icon: Icons.folder_zip_outlined,
          primary: true,
        ),
      );
    }
    if (filing.b2bInvoices.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1B2bCsv,
          label: 'GSTR-1 B2B Invoice CSV',
          subtitle: 'Registered customer invoices for IFF/GSTR-1',
          section: 'B2B Section CSV',
          icon: Icons.business_center_outlined,
        ),
      );
    }
    if (filing.hsnB2bSummary.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1HsnB2bCsv,
          label: 'HSN Table 12 B2B CSV',
          subtitle: 'HSN summary for registered customer sales',
          section: 'B2B Section CSV',
          icon: Icons.grid_view_outlined,
        ),
      );
    }
    return items;
  }

  static List<GstReportExportMenuItem> _b2cExportItems(
    GstReportSnapshot snapshot,
  ) {
    final filing = Gstr1FilingSnapshot.fromReport(snapshot);
    final items = <GstReportExportMenuItem>[];
    if (_hasPortalUploadDocuments(snapshot, GstFilingSegment.b2c)) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.b2cPortalUtilityPackZip,
          label: 'B2C Upload CSV Pack',
          subtitle: 'Official B2CL/B2CS and HSN B2C section files only',
          section: 'GST Portal Upload',
          icon: Icons.folder_zip_outlined,
          primary: true,
        ),
      );
    }
    if (filing.b2cLargeInvoices.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1B2clCsv,
          label: 'GSTR-1 B2CL CSV',
          subtitle: 'Large interstate B2C invoices only',
          section: 'B2C Section CSV',
          icon: Icons.storefront_outlined,
        ),
      );
    }
    if (filing.b2cSmallSummary.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1B2csCsv,
          label: 'GSTR-1 B2CS CSV',
          subtitle: 'Small B2C consolidated summary only',
          section: 'B2C Section CSV',
          icon: Icons.storefront_outlined,
        ),
      );
    }
    if (filing.hsnB2cSummary.isNotEmpty) {
      items.add(
        const GstReportExportMenuItem(
          action: GstReportExportAction.gstr1HsnB2cCsv,
          label: 'HSN Table 12 B2C CSV',
          subtitle: 'HSN summary for retail customer sales',
          section: 'B2C Section CSV',
          icon: Icons.grid_on_outlined,
        ),
      );
    }
    return items;
  }

  static bool _usesFullPeriodSnapshot(GstReportExportAction action) {
    return switch (action) {
      GstReportExportAction.portalUtilityPackZip ||
      GstReportExportAction.filingGuidePdf ||
      GstReportExportAction.gstr1DocumentsCsv ||
      GstReportExportAction.gstr3bCsv ||
      GstReportExportAction.summaryPdf ||
      GstReportExportAction.gstr1Csv ||
      GstReportExportAction.hsnCsv ||
      GstReportExportAction.hsnPdf ||
      GstReportExportAction.invoiceLedgerCsv ||
      GstReportExportAction.invoiceLedgerPdf =>
        true,
      GstReportExportAction.b2bPortalUtilityPackZip ||
      GstReportExportAction.b2cPortalUtilityPackZip ||
      GstReportExportAction.gstr1B2bCsv ||
      GstReportExportAction.gstr1B2clCsv ||
      GstReportExportAction.gstr1B2csCsv ||
      GstReportExportAction.gstr1HsnB2bCsv ||
      GstReportExportAction.gstr1HsnB2cCsv =>
        false,
    };
  }

  static bool _hasPortalUploadDocuments(
    GstReportSnapshot snapshot,
    GstFilingSegment? segment,
  ) {
    return GstReportPortalPackBuilder.documents(
      snapshot,
      segment: segment,
    ).isNotEmpty;
  }
}

class _SegmentFilingControlBar extends StatelessWidget {
  const _SegmentFilingControlBar({
    required this.segment,
    required this.snapshot,
    required this.controller,
    required this.onComplete,
  });

  final GstFilingSegment segment;
  final GstReportSnapshot snapshot;
  final GstReportController controller;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final completed = controller.isSegmentFilingComplete(segment);
    final hasActivity = _hasActivity(segment, snapshot);
    final noSales = !hasActivity && !completed;
    final enabled =
        hasActivity && controller.canCompleteSelectedPeriod && !completed;
    final statusColor = completed
        ? GstReportColors.success
        : noSales
            ? GstReportColors.textMuted
            : enabled
                ? GstReportColors.taxGreen
                : GstReportColors.warning;
    final amount = _segmentTaxPayable(segment, snapshot);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              completed
                  ? Icons.check_circle_rounded
                  : noSales
                      ? Icons.block_rounded
                      : Icons.pending_actions_rounded,
              color: statusColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed
                      ? '${segment.code} filing completed'
                      : noSales
                          ? '${segment.code} no sales'
                          : '${segment.code} filing completion',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _statusText(completed, enabled),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _MiniAmountPill(
            label: '${segment.code} GST',
            value: GstReportFormatters.money(amount),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: enabled ? onComplete : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(190, 42),
              backgroundColor: GstReportColors.taxGreen,
              disabledBackgroundColor: completed
                  ? GstReportColors.success.withValues(alpha: 0.12)
                  : GstReportColors.bodySubtle,
              disabledForegroundColor: completed
                  ? GstReportColors.success
                  : GstReportColors.textMuted.withValues(alpha: 0.72),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: Icon(
              completed
                  ? Icons.check_circle_rounded
                  : noSales
                      ? Icons.block_rounded
                      : Icons.verified_rounded,
              size: 18,
            ),
            label: Text(
              completed
                  ? 'Filing Completed'
                  : noSales
                      ? 'No Filing Required'
                      : 'Complete ${segment.code} Filing',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(bool completed, bool enabled) {
    if (completed) {
      return 'This month is marked complete and saved in GST filing records.';
    }
    if (!_hasActivity(segment, snapshot)) {
      return 'No GST sales found for this workspace in this period.';
    }
    if (enabled) {
      return 'Review the return checklist before marking this month complete.';
    }
    if (controller.isSelectedMonthInFuture) {
      return 'Future GST periods are locked.';
    }
    return 'Button opens on ${GstReportFormatters.date(controller.filingCompletionOpensAt)} after this GST month closes.';
  }

  double _segmentTaxPayable(
    GstFilingSegment segment,
    GstReportSnapshot snapshot,
  ) {
    final invoices = switch (segment) {
      GstFilingSegment.b2b => snapshot.gstr1B2bInvoices,
      GstFilingSegment.b2c => snapshot.gstr1B2cInvoices,
    };
    return invoices.fold<double>(0, (sum, row) => sum + row.gstAmount);
  }

  bool _hasActivity(GstFilingSegment segment, GstReportSnapshot snapshot) {
    final invoices = switch (segment) {
      GstFilingSegment.b2b => snapshot.gstr1B2bInvoices,
      GstFilingSegment.b2c => snapshot.gstr1B2cInvoices,
    };
    if (invoices.isNotEmpty) return true;
    if (snapshot.dashboard.taxableSales.abs() > 0.005) return true;
    if (snapshot.dashboard.totalGst.abs() > 0.005) return true;
    if (segment == GstFilingSegment.b2c) {
      return snapshot.dashboard.nonGstInvoiceCount > 0 ||
          snapshot.dashboard.taxReviewSales.abs() > 0.005;
    }
    return false;
  }
}

class _MiniAmountPill extends StatelessWidget {
  const _MiniAmountPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GstReportPageHeader extends StatelessWidget {
  const _GstReportPageHeader({this.segment});

  final GstFilingSegment? segment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          segment?.title ?? GstReportStrings.moduleTitle,
          style: GstReportStyles.pageTitle,
        ),
        const SizedBox(height: 4),
        Text(
          segment?.subtitle ??
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
