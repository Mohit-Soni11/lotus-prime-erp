import 'package:flutter/material.dart';

import '../../application/gst_report_controller.dart';
import '../../application/gst_report_segment_projector.dart';
import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';
import '../widgets/gst_filing_segment_card.dart';
import '../widgets/gst_report_app_bar.dart';
import '../widgets/gst_report_period_selector.dart';
import 'gst_report_screen.dart';

class GstReportHubScreen extends StatefulWidget {
  const GstReportHubScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<GstReportHubScreen> createState() => _GstReportHubScreenState();
}

class _GstReportHubScreenState extends State<GstReportHubScreen> {
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
            if (snapshot == null) return const _EmptyState();

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HubHeader(),
                    const SizedBox(height: 18),
                    GstReportPeriodSelector(controller: _controller),
                    const SizedBox(height: 18),
                    _QrmpStatusStrip(snapshot: snapshot),
                    const SizedBox(height: 18),
                    _SegmentGrid(
                      snapshot: snapshot,
                      onSegmentSelected: _openSegmentWorkspace,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openSegmentWorkspace(GstFilingSegment segment) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => GstReportScreen(
          segment: segment,
          initialTab: GstReportTab.dashboard,
          onBack: () => Navigator.of(context).pop(),
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

class _HubHeader extends StatelessWidget {
  const _HubHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GST Filing Control Center', style: GstReportStyles.pageTitle),
        const SizedBox(height: 4),
        Text(
          'Regular GST Registration with QRMP: quarterly return control and monthly tax payment visibility',
          style: GstReportStyles.body,
        ),
      ],
    );
  }
}

class _QrmpStatusStrip extends StatelessWidget {
  const _QrmpStatusStrip({required this.snapshot});

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GstReportColors.taxGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GstReportColors.taxGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GstReportColors.taxGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_repeat_rounded,
              color: GstReportColors.taxGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QRMP Mode: Quarterly Return + Monthly Tax Payment',
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${GstReportFormatters.monthLabel(snapshot.period)} is tracked monthly; quarterly archive will roll up from these monthly ledgers.',
                  style: GstReportStyles.body.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusPill(
            label: snapshot.identity.gstin.isEmpty
                ? 'GSTIN Pending'
                : snapshot.identity.gstin,
            color: snapshot.identity.gstin.isEmpty
                ? GstReportColors.warning
                : GstReportColors.success,
          ),
        ],
      ),
    );
  }
}

class _SegmentGrid extends StatelessWidget {
  const _SegmentGrid({
    required this.snapshot,
    required this.onSegmentSelected,
  });

  final GstReportSnapshot snapshot;
  final ValueChanged<GstFilingSegment> onSegmentSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 960
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final segment in GstFilingSegment.values)
              SizedBox(
                width: cardWidth,
                child: GstFilingSegmentCard(
                  segment: segment,
                  invoiceCount: _invoiceCount(segment),
                  taxableValue: _taxableValue(segment),
                  taxPayable: _taxPayable(segment),
                  auditCount: _auditCount(segment),
                  onTap: () => onSegmentSelected(segment),
                ),
              ),
          ],
        );
      },
    );
  }

  int _invoiceCount(GstFilingSegment segment) {
    switch (segment) {
      case GstFilingSegment.b2b:
        return snapshot.gstr1B2bInvoices.length;
      case GstFilingSegment.b2c:
        return snapshot.gstr1B2cInvoices.length;
    }
  }

  double _taxableValue(GstFilingSegment segment) {
    return _sum(_invoices(segment), (row) => row.taxableAmount);
  }

  double _taxPayable(GstFilingSegment segment) {
    return _sum(_invoices(segment), (row) => row.gstAmount);
  }

  int _auditCount(GstFilingSegment segment) {
    final projected = GstReportSegmentProjector.project(snapshot, segment);
    return projected.auditFindings
        .where((item) => item.severity != GstAuditSeverity.info)
        .length;
  }

  List<GstInvoiceRow> _invoices(GstFilingSegment segment) {
    switch (segment) {
      case GstFilingSegment.b2b:
        return snapshot.gstr1B2bInvoices;
      case GstFilingSegment.b2c:
        return snapshot.gstr1B2cInvoices;
    }
  }

  double _sum<T>(Iterable<T> rows, double Function(T row) selector) {
    return rows.fold<double>(0, (sum, row) => sum + selector(row));
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: GstReportStyles.body.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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
      child: Text('No GST filing data available.', style: GstReportStyles.body),
    );
  }
}
