import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final DayBookController ctrl;

  const DayBookAppBar({
    super.key,
    required this.onBack,
    required this.onRefresh,
    required this.ctrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

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
    return Material(
      color: DayBookColors.shellPanel,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: DayBookColors.shellBorder),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final showStatus = constraints.maxWidth >= 980;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
                child: Row(
                  children: [
                    _HeaderIconButton(
                      icon: DayBookIcons.back,
                      tooltip: 'Back',
                      onPressed: widget.onBack,
                    ),
                    SizedBox(width: compact ? 8 : 14),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            DayBookColors.brandGoldSoft.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              DayBookColors.brandGold.withValues(alpha: 0.38),
                        ),
                      ),
                      child: const Icon(
                        DayBookIcons.module,
                        color: DayBookColors.brandGold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
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
                            const SizedBox(height: 2),
                            Text(
                              DayBookStrings.moduleSubtitle,
                              style: DayBookStyles.appBarSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    if (showStatus) ...[
                      _LiveStatus(animation: _pulseController),
                      const SizedBox(width: 14),
                    ],
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
          fixedSize: const Size(38, 38),
          backgroundColor: Colors.transparent,
          foregroundColor: DayBookColors.shellMuted,
          disabledForegroundColor:
              DayBookColors.shellMuted.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DayBookColors.positive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DayBookColors.positive.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
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
          const SizedBox(width: 7),
          Text(
            DayBookStrings.liveStatus,
            style: DayBookStyles.appBarSubtitle.copyWith(
              color: DayBookColors.positiveBorder,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
