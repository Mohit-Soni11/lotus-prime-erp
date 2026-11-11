import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_export_button.dart';

/// Date and report actions for the complete Day Book workspace.
class DayBookWorkspaceHeader extends StatelessWidget {
  const DayBookWorkspaceHeader({
    super.key,
    required this.ctrl,
    required this.summary,
    required this.onDayClosing,
    required this.onAddIncome,
    required this.onBalanceVerification,
    required this.balanceSaved,
    required this.onViewPdf,
    required this.onExportCsv,
    required this.onSharePdf,
  });

  final DayBookController ctrl;
  final DayBookSummary summary;
  final VoidCallback onDayClosing;
  final VoidCallback? onAddIncome;
  final VoidCallback? onBalanceVerification;
  final bool balanceSaved;
  final VoidCallback? onViewPdf;
  final VoidCallback? onExportCsv;
  final VoidCallback? onSharePdf;

  @override
  Widget build(BuildContext context) {
    final export = DayBookExportButton(
      onViewPdf: onViewPdf,
      onExportCsv: onExportCsv,
      onSharePdf: onSharePdf,
    );
    final navigation = SizedBox(
      width: 266,
      child: _DateNavigation(ctrl: ctrl),
    );
    final dayClosing = _WorkspaceAction(
      label: summary.isDayLocked ? 'Day Closed' : 'Day Closing',
      icon: summary.isDayLocked
          ? Icons.lock_outline_rounded
          : Icons.task_alt_rounded,
      onPressed: summary.isDayLocked ? null : onDayClosing,
    );
    final balanceVerification = _WorkspaceAction(
      label: 'Balance Verification',
      icon: balanceSaved ? Icons.verified_outlined : Icons.fact_check_outlined,
      onPressed: onBalanceVerification,
    );
    final addIncome = _WorkspaceAction(
      label: 'Add Income',
      icon: Icons.add_circle_outline_rounded,
      onPressed: onAddIncome,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final inline = constraints.maxWidth >= 1320;
      return Container(
        color: DayBookColors.bodyPanel,
        padding: EdgeInsets.fromLTRB(0, inline ? 8 : 10, 12, 8),
        child: inline
            ? Row(children: [
                const Expanded(child: _WorkspaceHeading()),
                navigation,
                const SizedBox(width: 10),
                export,
                const SizedBox(width: 10),
                balanceVerification,
                const SizedBox(width: 10),
                addIncome,
                if (ctrl.isToday) ...[
                  const SizedBox(width: 10),
                  dayClosing,
                ],
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _WorkspaceHeading(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        navigation,
                        export,
                        balanceVerification,
                        addIncome,
                        if (ctrl.isToday) dayClosing,
                      ],
                    ),
                  ),
                ],
              ),
      );
    });
  }
}

class _WorkspaceAction extends StatelessWidget {
  const _WorkspaceAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Ink(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: onPressed == null
                  ? null
                  : const LinearGradient(colors: [
                      Color(0xFFE9C741),
                      Color(0xFFD6AD16),
                    ]),
              color: onPressed == null ? DayBookColors.bodyBorder : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 17, color: DayBookColors.textPrimary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DayBookStyles.button.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: DayBookColors.textPrimary,
                    )),
              ),
            ]),
          ),
        ),
      );
}

class _WorkspaceHeading extends StatelessWidget {
  const _WorkspaceHeading();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: const BoxDecoration(
              color: DayBookColors.brandGold,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'Day Book',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DayBookStyles.pageTitle,
            ),
          ),
        ],
      );
}

class _DateNavigation extends StatelessWidget {
  const _DateNavigation({required this.ctrl});

  final DayBookController ctrl;

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.bodySubtle,
          borderColor: DayBookColors.bodyBorder,
        ),
        child: Row(children: [
          _NavigationButton(
            tooltip: 'Previous day',
            onPressed: ctrl.goToPreviousDay,
            icon: Icons.chevron_left_rounded,
          ),
          Expanded(
            child: InkWell(
              onTap: () => ctrl.selectDate(context),
              child: Center(
                child: Text(
                  ctrl.isToday
                      ? 'Today · ${DateFormat('d MMM yyyy').format(ctrl.selectedDate)}'
                      : DateFormat('EEE, d MMM yyyy').format(ctrl.selectedDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.labelStrong.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: DayBookColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          _NavigationButton(
            tooltip: 'Next day',
            onPressed: ctrl.canGoNext ? ctrl.goToNextDay : null,
            icon: Icons.chevron_right_rounded,
          ),
          if (!ctrl.isToday)
            _NavigationButton(
              tooltip: 'Return to today',
              onPressed: ctrl.goToToday,
              icon: Icons.today_rounded,
            ),
        ]),
      );
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        color: DayBookColors.textPrimary,
        disabledColor: DayBookColors.textPrimary.withValues(alpha: 0.35),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      );
}
