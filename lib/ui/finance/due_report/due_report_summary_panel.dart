import 'package:flutter/material.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';

class DueReportSummaryPanel extends StatelessWidget {
  final DueReportStatsModel stats;
  final bool isLoading;

  const DueReportSummaryPanel({
    super.key,
    required this.stats,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 760 ? 2 : 4;
        const gap = 10.0;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _MetricCard(
              width: width,
              icon: DueReportIcons.totalDue,
              label: DueReportStrings.totalDue,
              value: DueReportController.formatCompact(stats.totalDue),
              detail: '${stats.billCount} bills pending',
              accent: DueReportColors.danger,
              soft: DueReportColors.dangerSoft,
              isLoading: isLoading,
            ),
            _MetricCard(
              width: width,
              icon: DueReportIcons.customers,
              label: DueReportStrings.customers,
              value: stats.customerCount.toString(),
              detail:
                  'Highest ${DueReportController.formatCompact(stats.highestCustomerDue)}',
              accent: DueReportColors.info,
              soft: DueReportColors.infoSoft,
              isLoading: isLoading,
            ),
            _MetricCard(
              width: width,
              icon: DueReportIcons.overdue,
              label: DueReportStrings.overdue,
              value: DueReportController.formatCompact(stats.overdueAmount),
              detail: '${stats.overdueBillCount} overdue bills',
              accent: DueReportColors.warning,
              soft: DueReportColors.warningSoft,
              isLoading: isLoading,
            ),
            _MetricCard(
              width: width,
              icon: DueReportIcons.dueToday,
              label: DueReportStrings.dueToday,
              value: stats.dueTodayBillCount.toString(),
              detail: '${stats.noPromiseBillCount} without promise date',
              accent: DueReportColors.teal,
              soft: DueReportColors.tealSoft,
              isLoading: isLoading,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;
  final Color soft;
  final bool isLoading;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
    required this.soft,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: 104,
        decoration: DueReportStyles.panel(),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: DueReportStyles.label),
                  const SizedBox(height: 5),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      isLoading ? '--' : value,
                      key: ValueKey('$label$value$isLoading'),
                      style: DueReportStyles.amount.copyWith(color: accent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLoading ? 'Loading...' : detail,
                    style: DueReportStyles.muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
