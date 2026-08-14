import 'package:flutter/material.dart';

import '../../application/gst_report_controller.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';

class GstReportPeriodSelector extends StatelessWidget {
  const GstReportPeriodSelector({
    super.key,
    required this.controller,
  });

  final GstReportController controller;

  @override
  Widget build(BuildContext context) {
    final period = controller.period;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: GstReportStyles.panel(),
      child: Row(
        children: [
          _MonthArrowButton(
            tooltip: 'Previous month',
            icon: Icons.chevron_left_rounded,
            onPressed: controller.isLoading
                ? null
                : () => controller.shiftReportMonth(-1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: controller.isLoading
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: period.startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                        helpText: 'Select GST Filing Month',
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      );
                      if (picked != null) {
                        controller.setReportMonth(picked);
                      }
                    },
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: GstReportColors.bodySubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GstReportColors.bodyBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      GstReportIcons.calendar,
                      color: GstReportColors.taxGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            GstReportFormatters.monthLabel(period),
                            style: GstReportStyles.body.copyWith(
                              color: GstReportColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            GstReportFormatters.periodLabel(period),
                            style: GstReportStyles.body.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _MonthArrowButton(
            tooltip: 'Next month',
            icon: Icons.chevron_right_rounded,
            onPressed: controller.isLoading
                ? null
                : () => controller.shiftReportMonth(1),
          ),
        ],
      ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size(46, 46),
          backgroundColor: GstReportColors.bodySubtle,
          foregroundColor: GstReportColors.textPrimary,
          disabledForegroundColor:
              GstReportColors.textMuted.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: GstReportColors.bodyBorder),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}
