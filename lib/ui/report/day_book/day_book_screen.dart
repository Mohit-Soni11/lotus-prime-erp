import 'package:flutter/material.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../logic/report/day_book/day_book_export_service.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_app_bar.dart';
import 'day_book_eod_dialog.dart';
import 'day_book_sections.dart';

class DayBookScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DayBookScreen({super.key, this.onBack});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  late final DayBookController _ctrl;
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _railScrollController = ScrollController();
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
    _railScrollController.dispose();
    super.dispose();
  }

  void _showReconciliation() {
    showDialog<void>(
      context: context,
      barrierColor: DayBookColors.overlay,
      builder: (context) => DayBookEodDialog(ctrl: _ctrl),
    );
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
      debugPrint('Day Book export failed: $error\n$stackTrace');
      _showNotice(DayBookStrings.exportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          onRefresh: _ctrl.loadData,
          onExportPdf: _exporting ? null : _previewPdf,
          onExportCsv: _exporting ? null : _exportCsv,
          onSharePdf: _exporting ? null : _sharePdf,
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

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1080) {
                  return _buildDesktop(summary);
                }
                return _buildCompact(summary);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktop(DayBookSummary summary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: DayBookColors.bodySubtle,
            border: Border(
              right: BorderSide(color: DayBookColors.bodyBorder),
            ),
          ),
          child: Scrollbar(
            controller: _railScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _railScrollController,
              padding: const EdgeInsets.all(16),
              child: DayBookSummaryRail(
                ctrl: _ctrl,
                onReconcile: _showReconciliation,
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildWorkspace(summary),
        ),
      ],
    );
  }

  Widget _buildWorkspace(DayBookSummary summary) {
    return Scrollbar(
      controller: _mainScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _mainScrollController,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 36),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Reveal(
                  delay: 0,
                  child: DayBookOpeningPosition(summary: summary),
                ),
                const SizedBox(height: 16),
                _Reveal(
                  delay: 40,
                  child: DayBookOverview(summary: summary),
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
        ),
      ),
    );
  }

  Widget _buildCompact(DayBookSummary summary) {
    return Scrollbar(
      controller: _mainScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _mainScrollController,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DayBookOpeningPosition(summary: summary),
            const SizedBox(height: 12),
            DayBookSummaryRail(
              ctrl: _ctrl,
              onReconcile: _showReconciliation,
              compact: true,
            ),
            const SizedBox(height: 16),
            if (summary.anomalies.isNotEmpty) ...[
              DayBookAlerts(ctrl: _ctrl),
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
      _Reveal(
        delay: 100,
        child: CashMovementPanel(summary: summary),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 860;
          final sales = SalesTaxPanel(summary: summary);
          final payments = PaymentMixPanel(summary: summary);

          if (stack) {
            return Column(
              children: [
                sales,
                const SizedBox(height: 12),
                payments,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: sales),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: payments),
            ],
          );
        },
      ),
      const SizedBox(height: 12),
      _Reveal(
        delay: 180,
        child: MetalMovementPanel(summary: summary),
      ),
      const SizedBox(height: 12),
      _Reveal(
        delay: 210,
        child: DayBookClosingPosition(summary: summary),
      ),
      if (_ctrl.isToday && summary.prediction != null) ...[
        const SizedBox(height: 12),
        _Reveal(
          delay: 230,
          child: ForecastPanel(prediction: summary.prediction!),
        ),
      ],
      const SizedBox(height: 12),
      _Reveal(
        delay: 280,
        child: DayBookClosePanel(
          summary: summary,
          isToday: _ctrl.isToday,
          onReconcile: _showReconciliation,
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1080) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: DayBookColors.bodySubtle,
                  border: Border(
                    right: BorderSide(color: DayBookColors.bodyBorder),
                  ),
                ),
                child: const _RailSkeleton(),
              ),
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(22),
                  child: _SkeletonColumn(),
                ),
              ),
            ],
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: const _SkeletonColumn(),
            ),
          ),
        );
      },
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 180,
          height: 40,
          decoration: BoxDecoration(
            color: DayBookColors.bodyBorder,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: DayBookColors.bodyPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DayBookColors.bodyBorder),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _railBlock()),
            const SizedBox(width: 8),
            Expanded(child: _railBlock()),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 128,
          decoration: BoxDecoration(
            color: DayBookColors.bodyPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DayBookColors.bodyBorder),
          ),
        ),
      ],
    );
  }

  Widget _railBlock() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: DayBookColors.bodyPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DayBookColors.bodyBorder),
      ),
    );
  }
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
