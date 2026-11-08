import 'package:flutter/material.dart';
import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../logic/report/day_book/day_book_export_service.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_app_bar.dart';
import 'day_book_cash_income_dialog.dart';
import 'day_book_balance_dialog.dart';
import 'day_book_top_section.dart';
import 'day_book_document_summary_panel.dart';
import 'day_book_eod_dialog.dart';
import 'day_book_receipts_register_panel.dart';
import 'day_book_primary_grid.dart';
import 'day_book_stock_added_panel.dart';
import 'day_book_sections.dart';
import '../../../core/logging/app_logger.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class DayBookScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DayBookScreen({super.key, this.onBack});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  late final DayBookController _ctrl;
  final ScrollController _mainScrollController = ScrollController();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = DayBookController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _showReconciliation() {
    showDialog<void>(
      context: context,
      barrierColor: DayBookColors.overlay,
      builder: (context) => DayBookEodDialog(ctrl: _ctrl),
    );
  }

  Future<void> _addCashIncome() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: DayBookColors.overlay,
      builder: (_) => DayBookCashIncomeDialog(
        date: _ctrl.selectedDate,
        onSave: _ctrl.addManualCashIncome,
      ),
    );
    if (saved == true) _showSuccess('Cash income saved in Day Book.');
  }

  Future<void> _setBalance() async {
    final flow = _ctrl.summary?.moneyFlow;
    if (flow == null) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: DayBookColors.overlay,
      builder: (_) => DayBookBalanceDialog(
        date: _ctrl.selectedDate,
        expectedCash: flow.openingCash,
        expectedBank: flow.openingBank,
        bankAccountConfigured: flow.bankAccountCount != 0,
        existing: _ctrl.balanceVerification,
        onSave: _ctrl.verifyBalance,
      ),
    );
    if (saved == true) _showSuccess('Daily balance verification saved.');
  }

  Future<void> _previewPdf() async {
    final summary = _ctrl.summary;
    if (summary == null) return;
    await _runExport(() => DayBookExportService.previewPdf(summary));
  }

  Future<void> _exportCsv() async {
    final summary = _ctrl.summary;
    if (summary == null) return;
    await _runExport(() async {
      final path = await DayBookExportService.exportCsv(summary);
      if (path != null) _showNotice(DayBookStrings.csvExported);
    });
  }

  Future<void> _sharePdf() async {
    final summary = _ctrl.summary;
    if (summary == null) return;
    await _runExport(() async {
      final shared = await DayBookExportService.sharePdf(summary);
      if (shared) _showNotice(DayBookStrings.shareOpened);
    });
  }

  Future<void> _runExport(Future<void> Function() action) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await action();
    } catch (error, stackTrace) {
      AppLogger.debug('Day Book export failed: $error\n$stackTrace');
      _showNotice(DayBookStrings.exportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showNotice(String message) {
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: AppFeedbackType.success,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DayBookStyles.theme,
      child: Scaffold(
        backgroundColor: DayBookColors.bodyBg,
        appBar: DayBookAppBar(
          onBack: widget.onBack ?? () => Navigator.of(context).pop(),
          ctrl: _ctrl,
        ),
        body: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, child) {
            if (_ctrl.isLoading && _ctrl.summary == null) {
              return const _LoadingState();
            }

            if (_ctrl.errorMessage != null && _ctrl.summary == null) {
              return _ErrorState(
                message: _ctrl.errorMessage!,
                onRetry: _ctrl.loadData,
              );
            }

            final summary = _ctrl.summary;
            if (summary == null) {
              return const _EmptyState();
            }

            return _buildWorkspace(summary);
          },
        ),
      ),
    );
  }

  Widget _buildWorkspace(DayBookSummary summary) {
    final compact = MediaQuery.sizeOf(context).width < 800;
    return Scrollbar(
      controller: _mainScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _mainScrollController,
        padding: EdgeInsets.fromLTRB(
            compact ? 14 : 20, compact ? 14 : 20, compact ? 14 : 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DayBookTopSection(
              ctrl: _ctrl,
              summary: summary,
              onReconcile: _showReconciliation,
              onViewPdf: _exporting ? null : _previewPdf,
              onExportCsv: _exporting ? null : _exportCsv,
              onSharePdf: _exporting ? null : _sharePdf,
            ),
            const SizedBox(height: 16),
            DayBookPrimaryGrid(
              summary: summary,
              onAddCashIncome: summary.isDayLocked ? null : _addCashIncome,
              showBalanceAction:
                  _ctrl.isToday || _ctrl.balanceVerification != null,
              balanceSaved: _ctrl.balanceVerification != null,
              onSetBalance: (_ctrl.isToday && !summary.isDayLocked) ||
                      _ctrl.balanceVerification != null
                  ? _setBalance
                  : null,
            ),
            const SizedBox(height: 16),
            if (summary.anomalies.isNotEmpty) ...[
              _Reveal(
                delay: 70,
                child: DayBookAlerts(ctrl: _ctrl),
              ),
              const SizedBox(height: 12),
            ],
            ..._workspaceSections(summary),
          ],
        ),
      ),
    );
  }

  List<Widget> _workspaceSections(DayBookSummary summary) {
    return [
      if (summary.moneyFlow == null) ...[
        _Reveal(
          delay: 100,
          child: CashMovementPanel(summary: summary),
        ),
        const SizedBox(height: 12),
      ],
      DayBookDocumentSummaryPanel(
        summary: summary,
      ),
      const SizedBox(height: 12),
      DayBookReceiptsRegisterPanel(
        summary: summary,
      ),
      const SizedBox(height: 12),
      _Reveal(
        delay: 180,
        child: DayBookStockAddedPanel(
          summary: summary,
        ),
      ),
    ];
  }
}

class _Reveal extends StatelessWidget {
  final int delay;
  final Widget child;

  const _Reveal({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _SkeletonColumn(),
      );
}

class _SkeletonColumn extends StatefulWidget {
  const _SkeletonColumn();

  @override
  State<_SkeletonColumn> createState() => _SkeletonColumnState();
}

class _SkeletonColumnState extends State<_SkeletonColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = Color.lerp(
          DayBookColors.bodyBorder,
          DayBookColors.bodySubtle,
          _controller.value,
        )!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SkeletonBlock(height: 44, width: 180, color: color),
            const SizedBox(height: 14),
            _SkeletonBlock(
              height: 108,
              color: color,
            ),
            const SizedBox(height: 12),
            _SkeletonBlock(height: 180, color: color),
            const SizedBox(height: 12),
            _SkeletonBlock(height: 260, color: color),
          ],
        );
      },
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;
  final double? width;
  final Color color;

  const _SkeletonBlock({
    required this.height,
    required this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: DayBookColors.negativeSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DayBookColors.negativeBorder),
                ),
                child: const Icon(
                  DayBookIcons.error,
                  color: DayBookColors.negative,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DayBookStrings.errorTitle,
                style: DayBookStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: DayBookStyles.sectionSubtitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(DayBookIcons.refresh, size: 17),
                label: const Text(DayBookStrings.retry),
              ),
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: DayBookColors.bodySubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DayBookColors.bodyBorder),
              ),
              child: const Icon(
                DayBookIcons.module,
                color: DayBookColors.textMuted,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              DayBookStrings.noDataTitle,
              style: DayBookStyles.sectionTitle,
            ),
            const SizedBox(height: 5),
            Text(
              DayBookStrings.noDataSubtitle,
              style: DayBookStyles.sectionSubtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
