import 'package:flutter/material.dart';

import '../../../models/finance/due_report/due_report_model.dart';
import '../../../theme/finance/due_report/due_report_theme.dart';

class DueReportFilterChip extends StatelessWidget {
  const DueReportFilterChip({
    super.key,
    required this.filter,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final DueReportFilter filter;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final (icon, accent, soft) = switch (filter) {
      DueReportFilter.all => (
          Icons.receipt_long_rounded,
          DueReportColors.gold,
          DueReportColors.goldSoft,
        ),
      DueReportFilter.overdue => (
          Icons.warning_amber_rounded,
          DueReportColors.danger,
          DueReportColors.dangerSoft,
        ),
      DueReportFilter.dueToday => (
          Icons.today_rounded,
          DueReportColors.teal,
          DueReportColors.tealSoft,
        ),
      DueReportFilter.partial => (
          Icons.pie_chart_rounded,
          DueReportColors.info,
          DueReportColors.infoSoft,
        ),
      DueReportFilter.unpaid => (
          Icons.payments_outlined,
          DueReportColors.warning,
          DueReportColors.warningSoft,
        ),
      DueReportFilter.noPromise => (
          Icons.event_busy_rounded,
          DueReportColors.indigo,
          DueReportColors.indigoSoft,
        ),
    };

    return Material(
      color: selected ? soft : DueReportColors.panelBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent : DueReportColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 7),
              Text(
                filter.label,
                style: DueReportStyles.label.copyWith(
                  color: DueReportColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : soft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: DueReportStyles.label.copyWith(
                    color: DueReportColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
