import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/report/sales_report/sales_report_controller.dart';
import '../../../models/reports/sales_report/sales_report_models.dart';
import '../../../theme/reports/sales_report/sales_report_theme.dart';

class SalesReportMonthTaxFilter extends StatelessWidget {
  final SalesReportController controller;

  const SalesReportMonthTaxFilter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SalesReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalesReportColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
            color: SalesReportColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _MonthNavigator(
            month: filter.startDate,
            onPrevious: () => controller.shiftReportMonth(-1),
            onNext: () => controller.shiftReportMonth(1),
            onPickMonth: () async {
              final picked = await showDialog<DateTime>(
                context: context,
                builder: (_) =>
                    _MonthPickerDialog(initialMonth: filter.startDate),
              );
              if (picked != null) controller.setReportMonth(picked);
            },
          ),
          _TaxModeSegment(
            value: filter.taxMode,
            onChanged: controller.setTaxMode,
          ),
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickMonth;

  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPickMonth,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy').format(month);

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: SalesReportColors.goldGradientStart.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: SalesReportColors.brandGold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous month',
            onPressed: onPrevious,
          ),
          InkWell(
            onTap: onPickMonth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    SalesReportIcons.calendar,
                    size: 15,
                    color: SalesReportColors.brandGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: SalesReportStyles.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: SalesReportColors.brandGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _CompactIconButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next month',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        color: SalesReportColors.brandGold,
        style: IconButton.styleFrom(
          fixedSize: const Size(38, 38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

class _TaxModeSegment extends StatelessWidget {
  final SalesReportTaxMode value;
  final ValueChanged<SalesReportTaxMode> onChanged;

  const _TaxModeSegment({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SalesReportTaxMode>(
      showSelectedIcon: false,
      selected: {value},
      segments: const [
        ButtonSegment(
          value: SalesReportTaxMode.all,
          label: Text('All Invoices'),
          icon: Icon(Icons.layers_rounded, size: 16),
        ),
        ButtonSegment(
          value: SalesReportTaxMode.gst,
          label: Text('GST Invoice'),
          icon: Icon(Icons.verified_rounded, size: 16),
        ),
        ButtonSegment(
          value: SalesReportTaxMode.nonGst,
          label: Text('Non-GST Invoice'),
          icon: Icon(Icons.receipt_rounded, size: 16),
        ),
      ],
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SalesReportColors.textPrimary;
          }
          return SalesReportColors.textSecondary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SalesReportColors.brandGold.withValues(alpha: 0.18);
          }
          return SalesReportColors.bodyPanel;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: SalesReportColors.bodyBorder),
        ),
        textStyle: WidgetStateProperty.all(
          SalesReportStyles.body.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      onSelectionChanged: (selected) {
        if (selected.isEmpty) return;
        onChanged(selected.first);
      },
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialMonth;

  const _MonthPickerDialog({required this.initialMonth});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _month;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
    _month = widget.initialMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Report Month'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous year',
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_year',
                      style: SalesReportStyles.pageTitle.copyWith(
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next year',
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.85,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final selected = month == _month;
                return OutlinedButton(
                  onPressed: () => setState(() => _month = month),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? SalesReportColors.brandGold.withValues(alpha: 0.16)
                        : SalesReportColors.bodyPanel,
                    side: BorderSide(
                      color: selected
                          ? SalesReportColors.brandGold
                          : SalesReportColors.bodyBorder,
                    ),
                  ),
                  child: Text(
                    _months[index],
                    style: SalesReportStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? SalesReportColors.brandGold
                          : SalesReportColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(DateTime(_year, _month)),
          child: const Text('Open Report'),
        ),
      ],
    );
  }
}
