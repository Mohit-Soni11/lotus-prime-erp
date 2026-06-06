import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportCsv;
  final VoidCallback? onSharePdf;
  final DayBookController ctrl;

  const DayBookAppBar({
    super.key,
    required this.onBack,
    required this.onRefresh,
    required this.onExportPdf,
    required this.onExportCsv,
    required this.onSharePdf,
    required this.ctrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  State<DayBookAppBar> createState() => _DayBookAppBarState();
}

class _DayBookAppBarState extends State<DayBookAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: DayBookColors.shellPanel,
        border: Border(
          bottom: BorderSide(color: DayBookColors.shellBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final showUtilities = constraints.maxWidth >= 1120;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
                child: Row(
                  children: [
                    _HeaderIconButton(
                      icon: DayBookIcons.back,
                      tooltip: 'Back',
                      onPressed: widget.onBack,
                    ),
                    SizedBox(width: compact ? 10 : 18),
                    if (!compact) ...[
                      Container(
                        width: 1.5,
                        height: 32,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              DayBookColors.shellBorder,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                    ],
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            DayBookColors.goldGradientStart,
                            DayBookColors.brandGold,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                DayBookColors.brandGold.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        DayBookIcons.module,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (!compact)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DayBookStrings.moduleTitle,
                              style: DayBookStyles.appBarTitle,
                            ),
                            const SizedBox(height: 3),
                            _LiveStatus(animation: _pulseController),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    ListenableBuilder(
                      listenable: widget.ctrl,
                      builder: (context, child) {
                        return _DateControl(
                          ctrl: widget.ctrl,
                          compact: compact,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    if (showUtilities) ...[
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: DayBookColors.shellBorder,
                      ),
                      _HeaderIconButton(
                        icon: DayBookIcons.pdf,
                        tooltip: DayBookStrings.exportPdf,
                        onPressed: widget.onExportPdf,
                      ),
                      const SizedBox(width: 6),
                      _HeaderIconButton(
                        icon: DayBookIcons.table,
                        tooltip: DayBookStrings.exportCsv,
                        onPressed: widget.onExportCsv,
                      ),
                      const SizedBox(width: 6),
                      _HeaderIconButton(
                        icon: DayBookIcons.share,
                        tooltip: DayBookStrings.sharePdf,
                        onPressed: widget.onSharePdf,
                      ),
                      const SizedBox(width: 6),
                    ],
                    ListenableBuilder(
                      listenable: widget.ctrl,
                      builder: (context, child) {
                        return _HeaderIconButton(
                          icon: DayBookIcons.refresh,
                          tooltip: DayBookStrings.refresh,
                          onPressed:
                              widget.ctrl.isLoading ? null : widget.onRefresh,
                          loading: widget.ctrl.isLoading,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DateControl extends StatelessWidget {
  final DayBookController ctrl;
  final bool compact;

  const _DateControl({
    required this.ctrl,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = ctrl.isToday
        ? 'Today'
        : DateFormat(compact ? 'd MMM' : 'd MMM yyyy')
            .format(ctrl.selectedDate);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: DayBookColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DayBookColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DateButton(
            icon: DayBookIcons.previous,
            tooltip: 'Previous day',
            onPressed: ctrl.goToPreviousDay,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => ctrl.selectDate(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: compact ? 62 : 112,
                maxWidth: compact ? 82 : 132,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      DayBookIcons.calendar,
                      size: 14,
                      color: DayBookColors.brandGold,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        dateLabel,
                        style: DayBookStyles.appBarSubtitle.copyWith(
                          color: DayBookColors.shellTitle,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _DateButton(
            icon: DayBookIcons.next,
            tooltip: 'Next day',
            onPressed: ctrl.canGoNext ? ctrl.goToNextDay : null,
          ),
          if (!compact && !ctrl.isToday) ...[
            Container(
              width: 1,
              height: 22,
              color: DayBookColors.shellBorder,
            ),
            Tooltip(
              message: DayBookStrings.returnToToday,
              child: InkWell(
                onTap: ctrl.goToToday,
                borderRadius: BorderRadius.circular(6),
                child: const SizedBox(
                  width: 38,
                  height: 36,
                  child: Icon(
                    DayBookIcons.today,
                    size: 16,
                    color: DayBookColors.brandGold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _DateButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 34,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null
                ? DayBookColors.shellMuted.withValues(alpha: 0.35)
                : DayBookColors.shellMuted,
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool loading;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size(42, 42),
          backgroundColor: DayBookColors.shellBorder.withValues(alpha: 0.3),
          foregroundColor: DayBookColors.shellTitle,
          disabledForegroundColor:
              DayBookColors.shellMuted.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: DayBookColors.shellBorder),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DayBookColors.brandGold,
                ),
              )
            : Icon(icon, size: 18),
      ),
    );
  }
}

class _LiveStatus extends StatelessWidget {
  final Animation<double> animation;

  const _LiveStatus({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: animation,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: DayBookColors.positive,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          DayBookStrings.liveStatus,
          style: DayBookStyles.appBarSubtitle.copyWith(
            color: DayBookColors.positiveBorder,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
