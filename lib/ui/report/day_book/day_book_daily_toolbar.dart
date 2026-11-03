import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_export_button.dart';
import 'day_book_overview_cards.dart';

class DayBookDailyToolbar extends StatelessWidget {
  const DayBookDailyToolbar({
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DayBookStyles.panel(),
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 1050;
        final navigation = SizedBox(
          width: narrow ? constraints.maxWidth : 310,
          child: _DateNavigation(ctrl: ctrl),
        );
        final metrics = DayBookOverviewCards(summary: summary);
        final action = ctrl.isToday
            ? FilledButton.icon(
                onPressed: summary.isDayLocked ? null : onReconcile,
                icon: Icon(summary.isDayLocked
                    ? Icons.lock_outline_rounded
                    : Icons.fact_check_outlined),
                label: Text(
                    summary.isDayLocked ? 'Day Reconciled' : 'Reconcile Cash'),
              )
            : const SizedBox.shrink();
        final export = DayBookExportButton(
          onViewPdf: onViewPdf,
          onExportCsv: onExportCsv,
          onSharePdf: onSharePdf,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (narrow) ...[
              Text('Daily Overview', style: DayBookStyles.sectionTitle),
              const SizedBox(height: 10),
              navigation,
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [
                export,
                if (ctrl.isToday) action,
              ]),
              const SizedBox(height: 12),
              metrics,
            ] else ...[
              Row(children: [
                Expanded(
                  child:
                      Text('Daily Overview', style: DayBookStyles.sectionTitle),
                ),
                navigation,
                const SizedBox(width: 10),
                export,
                if (ctrl.isToday) ...[
                  const SizedBox(width: 12),
                  action,
                ],
              ]),
              const SizedBox(height: 14),
              metrics,
            ],
          ],
        );
      }),
    );
  }
}

class _DateNavigation extends StatelessWidget {
  const _DateNavigation({required this.ctrl});

  final DayBookController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: DayBookStyles.softPanel(
        color: DayBookColors.bodySubtle,
        borderColor: DayBookColors.bodyBorder,
      ),
      child: Row(children: [
        IconButton(
          tooltip: 'Previous day',
          onPressed: ctrl.goToPreviousDay,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: InkWell(
            onTap: () => ctrl.selectDate(context),
            child: Center(
              child: Text(
                ctrl.isToday
                    ? 'Today · ${DateFormat('d MMM yyyy').format(ctrl.selectedDate)}'
                    : DateFormat('EEE, d MMM yyyy').format(ctrl.selectedDate),
                style: DayBookStyles.labelStrong.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next day',
          onPressed: ctrl.canGoNext ? ctrl.goToNextDay : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        if (!ctrl.isToday)
          IconButton(
            tooltip: 'Return to today',
            onPressed: ctrl.goToToday,
            icon: const Icon(Icons.today_rounded),
          ),
      ]),
    );
  }
}
