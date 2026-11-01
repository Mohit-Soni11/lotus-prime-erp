import 'package:flutter/material.dart';

import '../../../logic/finance/due_report/due_report_controller.dart';
import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';

class DueReportSummaryPanel extends StatelessWidget {
  const DueReportSummaryPanel({
    super.key,
    required this.stats,
    required this.isLoading,
  });

  final DueReportStatsModel stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric(
        icon: DueReportIcons.totalDue,
        label: DueReportStrings.totalDue,
        value: DueReportController.formatAmount(stats.totalDue),
        detail: '${stats.billCount} open bills',
        accent: DueReportColors.danger,
        soft: DueReportColors.dangerSoft,
      ),
      _Metric(
        icon: DueReportIcons.customers,
        label: DueReportStrings.customers,
        value: stats.customerCount.toString(),
        detail: 'Customers with an outstanding balance',
        accent: DueReportColors.info,
        soft: DueReportColors.infoSoft,
      ),
      _Metric(
        icon: DueReportIcons.overdue,
        label: DueReportStrings.overdue,
        value: DueReportController.formatAmount(stats.overdueAmount),
        detail: '${stats.overdueBillCount} overdue bills',
        accent: DueReportColors.warning,
        soft: DueReportColors.warningSoft,
      ),
      _Metric(
        icon: DueReportIcons.dueToday,
        label: DueReportStrings.dueToday,
        value: stats.dueTodayBillCount.toString(),
        detail: 'Bills scheduled for today',
        accent: DueReportColors.teal,
        soft: DueReportColors.tealSoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 380
            ? 1
            : constraints.maxWidth < 1120
                ? 2
                : 4;
        const gap = 12.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: cardWidth,
                child: _MetricCard(metric: metric, isLoading: isLoading),
              ),
          ],
        );
      },
    );
  }
}

class _Metric {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
    required this.soft,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;
  final Color soft;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.isLoading});

  final _Metric metric;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(16),
      decoration: DueReportStyles.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: metric.soft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: metric.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(metric.icon, color: metric.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metric.label,
                  style: DueReportStyles.label.copyWith(
                    color: DueReportColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Tooltip(
            message: metric.value,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                isLoading ? '--' : metric.value,
                key: ValueKey('${metric.label}:${metric.value}:$isLoading'),
                style: DueReportStyles.amount.copyWith(fontSize: 23),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isLoading ? 'Loading...' : metric.detail,
            style: DueReportStyles.label.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
