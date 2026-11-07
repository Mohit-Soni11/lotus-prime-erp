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
    required this.onReconcile,
    required this.onViewPdf,
    required this.onExportCsv,
    required this.onSharePdf,
  });

  final DayBookController ctrl;
  final DayBookSummary summary;
  final VoidCallback onReconcile;
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
    final reconcile = _ReconcileAction(
      locked: summary.isDayLocked,
      onPressed: onReconcile,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final inline = constraints.maxWidth >= 1030;
      return Container(
        color: DayBookColors.bodyPanel,
        padding: EdgeInsets.fromLTRB(0, inline ? 8 : 10, 12, 8),
        child: inline
            ? Row(children: [
                const Expanded(child: _WorkspaceHeading()),
                navigation,
                const SizedBox(width: 10),
                export,
                if (ctrl.isToday) ...[
                  const SizedBox(width: 10),
                  reconcile,
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
                        if (ctrl.isToday) reconcile,
                      ],
                    ),
                  ),
                ],
              ),
      );
    });
  }
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

class _ReconcileAction extends StatelessWidget {
  const _ReconcileAction({required this.locked, required this.onPressed});

  final bool locked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: locked ? null : onPressed,
          child: Ink(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              gradient: locked
                  ? null
                  : const LinearGradient(colors: [
                      Color(0xFFE9C741),
                      Color(0xFFD6AD16),
                    ]),
              color: locked ? DayBookColors.bodyBorder : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                locked ? Icons.lock_outline_rounded : Icons.payments_outlined,
                size: 17,
                color: DayBookColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                locked ? 'Day Reconciled' : 'Reconcile Cash',
                style: DayBookStyles.button.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: DayBookColors.textPrimary,
                ),
              ),
            ]),
          ),
        ),
      );
}
