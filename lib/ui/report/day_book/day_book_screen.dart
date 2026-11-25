import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_routes.dart';
import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../logic/report/day_book/day_book_export_service.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_app_bar.dart';
import 'day_book_income_dialog.dart';
import 'day_book_form_navigation.dart';
import 'day_book_top_section.dart';
import 'day_book_document_summary_panel.dart';
import 'day_book_receipts_register_panel.dart';
import 'day_book_primary_grid.dart';
import 'day_book_stock_added_panel.dart';
import 'day_book_timeline_panel.dart';
import '../../../core/logging/app_logger.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class DayBookScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final DateTime? initialDate;
  final String? initialAction;
  final bool exitAfterClose;

  /// An injected controller remains owned by its caller.
  final DayBookController? controller;

  const DayBookScreen(
      {super.key,
      this.onBack,
      this.initialDate,
      this.initialAction,
      this.exitAfterClose = false,
      this.controller});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  late final DayBookController _ctrl;
  late final bool _ownsController;
  final ScrollController _mainScrollController = ScrollController();
  bool _exporting = false;
  bool _initialActionScheduled = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ctrl =
        widget.controller ?? DayBookController(initialDate: widget.initialDate);
    _ctrl.addListener(_handleInitialAction);
    _handleInitialAction();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_handleInitialAction);
    if (_ownsController) _ctrl.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<bool> _showDayClosing() async {
    final draft = await DayBookFormNavigation.closeDay(
      context,
      _ctrl,
    );
    if (!mounted) return false;
    if (draft == null) {
      return _ctrl.lastCloseSucceeded || _ctrl.summary?.isDayLocked == true;
    }
    await context.push(RoutePaths.financeExpense, extra: draft);
    if (!mounted) return false;
    await _ctrl.loadData(silent: true);
    if (!mounted || _ctrl.summary?.isDayLocked == true) {
      return _ctrl.lastCloseSucceeded || _ctrl.summary?.isDayLocked == true;
    }

    // A shortage Expense Entry is a step inside the same close-of-day task.
    // Keep the Day Closing workspace and its typed count available on return.
    return _showDayClosing();
  }

  bool get _isRequestedDay {
    final requested = widget.initialDate;
    final selected = _ctrl.selectedDate;
    return requested != null &&
        requested.year == selected.year &&
        requested.month == selected.month &&
        requested.day == selected.day;
  }

  void _handleInitialAction() {
    if (_initialActionScheduled ||
        widget.initialAction == null ||
        _ctrl.isLoading ||
        _ctrl.summary == null ||
        _ctrl.errorMessage != null) {
      return;
    }
    _initialActionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_ctrl.summary!.isDayLocked) {
        if (widget.exitAfterClose) _finishExitRequest(true);
        return;
      }
      if (widget.initialAction == 'verify') {
        await _setBalance();
      } else if (widget.initialAction == 'close') {
        final closed = await _showDayClosing();
        if (mounted && _isRequestedDay && widget.exitAfterClose) {
          _finishExitRequest(closed);
        }
        return;
      }
      if (mounted && _isRequestedDay && widget.exitAfterClose) {
        _finishExitRequest(_ctrl.summary?.isDayLocked == true);
      }
    });
  }

  void _finishExitRequest(bool closed) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop(closed);
    } else {
      router.go(RoutePaths.dashboard);
    }
  }

  Future<void> _addIncome() async {
    try {
      final bankAccounts = await _ctrl.loadIncomeBankAccounts();
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        barrierColor: DayBookColors.overlay,
        builder: (_) => DayBookIncomeDialog(
          date: _ctrl.selectedDate,
          bankAccounts: bankAccounts,
          onSave: _ctrl.addManualIncome,
        ),
      );
      if (saved == true) _showSuccess('Income saved in Day Book.');
    } catch (error, stackTrace) {
      AppLogger.debug(
          'Income bank accounts could not be loaded: $error\n$stackTrace');
      _showNotice('Bank accounts could not be loaded. Try again.');
    }
  }

  Future<void> _setBalance() async {
    final day = _ctrl.selectedDate;
    final result = await DayBookFormNavigation.verifyOpening(context, _ctrl);
    if (!mounted || result == null) return;
    final amount = result.mismatchExpenseAmount;
    if (amount != null) {
      final location = Uri(
        path: RoutePaths.financeExpense,
        queryParameters: {'date': day.toIso8601String()},
      );
      await context.push(location.toString(), extra: amount);
      if (mounted) await _ctrl.loadData(silent: true);
      return;
    }
    _showSuccess('Daily balance verification saved.');
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
      if (mounted) {
        AppFeedback.warning(context,
            message: 'Day Book export failed: '
                '${error.toString().replaceFirst('Bad state: ', '')}');
      }
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
              allowDayClosing: widget.initialAction != null && _isRequestedDay,
              ctrl: _ctrl,
              summary: summary,
              onDayClosing: _showDayClosing,
              onAddIncome: summary.isDayLocked ? null : _addIncome,
              onBalanceVerification: ((_ctrl.isToday ||
                              (widget.initialAction != null &&
                                  _isRequestedDay)) &&
                          !summary.isDayLocked) ||
                      _ctrl.balanceVerification != null
                  ? _setBalance
                  : null,
              balanceSaved: _ctrl.balanceVerification != null,
              onViewPdf: _exporting ? null : _previewPdf,
              onExportCsv: _exporting ? null : _exportCsv,
              onSharePdf: _exporting ? null : _sharePdf,
            ),
            const SizedBox(height: 16),
            DayBookPrimaryGrid(summary: summary),
            const SizedBox(height: 16),
            ..._workspaceSections(summary),
          ],
        ),
      ),
    );
  }

  List<Widget> _workspaceSections(DayBookSummary summary) {
    return [
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
      const SizedBox(height: 12),
      DayBookTimelinePanel(summary: summary),
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
