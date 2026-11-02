import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_export_button.dart';

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
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        final metricWidth =
            (constraints.maxWidth - (columns - 1) * 10) / columns;
        final metrics = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
                width: metricWidth,
                child: _DailyMetric(
                  label: 'Tax Invoices',
                  value: '${summary.totalGstBills}',
                  icon: DayBookIcons.tax,
                )),
            SizedBox(
                width: metricWidth,
                child: _DailyMetric(
                  label: 'Regular Invoices',
                  value: '${summary.totalNonGstBills}',
                  icon: DayBookIcons.regularInvoice,
                )),
            SizedBox(
                width: metricWidth,
                child: _DailyMetric(
                  label: 'GST Collected',
                  value: NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                      .format(summary.totalGstCollected),
                  icon: DayBookIcons.tax,
                )),
          ],
        );
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

class _DailyMetric extends StatelessWidget {
  const _DailyMetric(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.bodySubtle,
          borderColor: DayBookColors.bodyBorder,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: DayBookColors.brandGold),
          const SizedBox(width: 9),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: DayBookStyles.labelStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(value,
                  style: DayBookStyles.valueLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      );
}
