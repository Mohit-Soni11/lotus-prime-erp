import 'package:flutter/material.dart';

import '../../application/gst_report_controller.dart';
import '../../domain/gst_filing_period.dart';
import '../../domain/gst_report_models.dart';
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
    final filing = GstFilingPeriod.fromMonth(controller.period.month);
    final stateCode = controller.snapshot?.identity.stateCode ?? '';
    final snapshot = controller.snapshot;
    final workflow = controller.workflowSnapshot;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GstReportColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PeriodHeader(
            filing: filing,
            disabled: controller.isLoading,
            onPreviousMonth: () => controller.shiftReportMonth(-1),
            onNextMonth: controller.canShiftReportMonth(1)
                ? () => controller.shiftReportMonth(1)
                : null,
            onOpenPicker: () => _openPeriodPicker(context, filing),
          ),
          const SizedBox(height: 14),
          _QuarterTimeline(
            filing: filing,
            workflow: workflow,
            disabled: controller.isLoading,
            canSelectMonth: controller.canSelectMonth,
            onMonthSelected: controller.setReportMonth,
          ),
          const SizedBox(height: 14),
          _DueDateStrip(
            filing: filing,
            stateCode: stateCode,
            snapshot: snapshot,
            workflow: workflow,
          ),
        ],
      ),
    );
  }

  Future<void> _openPeriodPicker(
    BuildContext context,
    GstFilingPeriod filing,
  ) async {
    if (controller.isLoading) return;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _GstPeriodPickerDialog(
        initialMonth: filing.month,
        canSelectMonth: controller.canSelectMonth,
      ),
    );
    if (picked != null) {
      controller.setReportMonth(picked);
    }
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({
    required this.filing,
    required this.disabled,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onOpenPicker,
  });

  final GstFilingPeriod filing;
  final bool disabled;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MonthArrowButton(
          tooltip: 'Previous GST month',
          icon: Icons.chevron_left_rounded,
          onPressed: disabled ? null : onPreviousMonth,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: disabled ? null : onOpenPicker,
            child: Container(
              constraints: const BoxConstraints(minHeight: 62),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: GstReportColors.bodySubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GstReportColors.bodyBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GstReportColors.taxGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_tree_rounded,
                      color: GstReportColors.taxGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${filing.financialYearLabel}  |  ${filing.quarterLabel} ${filing.quarterRangeLabel}  |  ${GstReportFormatters.monthYear(filing.month)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GstReportStyles.body.copyWith(
                            color: GstReportColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Month ${filing.monthPositionInQuarter} of 3 in ${filing.quarterLabel}; cycle resets every financial year.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GstReportStyles.body.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: GstReportColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _MonthArrowButton(
          tooltip: 'Next GST month',
          icon: Icons.chevron_right_rounded,
          onPressed: disabled ? null : onNextMonth,
        ),
      ],
    );
  }
}

class _QuarterTimeline extends StatelessWidget {
  const _QuarterTimeline({
    required this.filing,
    required this.workflow,
    required this.disabled,
    required this.canSelectMonth,
    required this.onMonthSelected,
  });

  final GstFilingPeriod filing;
  final GstFilingWorkflowSnapshot? workflow;
  final bool disabled;
  final bool Function(DateTime month) canSelectMonth;
  final ValueChanged<DateTime> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;
        final width =
            compact ? constraints.maxWidth : (constraints.maxWidth - 30) / 4;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final quarter in filing.financialYearQuarters)
              SizedBox(
                width: width,
                child: _QuarterBlock(
                  quarter: quarter,
                  selectedMonth: filing.month,
                  currentMonth: DateTime(now.year, now.month),
                  completed: workflow?.isQuarterComplete(
                        GstFilingPeriod.fromMonth(quarter.months.first)
                            .quarterKey,
                      ) ??
                      false,
                  disabled: disabled,
                  canSelectMonth: canSelectMonth,
                  onMonthSelected: onMonthSelected,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuarterBlock extends StatelessWidget {
  const _QuarterBlock({
    required this.quarter,
    required this.selectedMonth,
    required this.currentMonth,
    required this.completed,
    required this.disabled,
    required this.canSelectMonth,
    required this.onMonthSelected,
  });

  final GstQuarterCycle quarter;
  final DateTime selectedMonth;
  final DateTime currentMonth;
  final bool completed;
  final bool disabled;
  final bool Function(DateTime month) canSelectMonth;
  final ValueChanged<DateTime> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final selected =
        quarter.months.any((month) => _sameMonth(month, selectedMonth));
    return SizedBox(
      height: 104,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? GstReportColors.taxGreen.withValues(alpha: 0.08)
              : GstReportColors.bodySubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? GstReportColors.taxGreen.withValues(alpha: 0.34)
                : GstReportColors.bodyBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${quarter.label} ${GstReportFormatters.shortMonth(quarter.months.first)}-${GstReportFormatters.shortMonth(quarter.months.last)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GstReportStyles.body.copyWith(
                      color: selected || completed
                          ? GstReportColors.taxGreen
                          : GstReportColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (completed)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: GstReportColors.success,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: completed
                  ? Text(
                      'Quarter filed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GstReportStyles.body.copyWith(
                        color: GstReportColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const Spacer(),
            Row(
              children: [
                for (final month in quarter.months) ...[
                  Expanded(
                    child: _MonthChip(
                      month: month,
                      selected: _sameMonth(month, selectedMonth),
                      current: _sameMonth(month, currentMonth),
                      disabled: disabled || !canSelectMonth(month),
                      onTap: () => onMonthSelected(month),
                    ),
                  ),
                  if (month != quarter.months.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.month,
    required this.selected,
    required this.current,
    required this.disabled,
    required this.onTap,
  });

  final DateTime month;
  final bool selected;
  final bool current;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? GstReportColors.textMuted.withValues(alpha: 0.55)
        : selected
            ? GstReportColors.taxGreen
            : GstReportColors.textSecondary;
    return Tooltip(
      message: disabled
          ? '${GstReportFormatters.monthYear(month)} is locked until the month starts'
          : GstReportFormatters.monthYear(month),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? GstReportColors.taxGreen
                : current
                    ? GstReportColors.brandGold.withValues(alpha: 0.13)
                    : disabled
                        ? GstReportColors.bodySubtle.withValues(alpha: 0.55)
                        : GstReportColors.bodyPanel,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? GstReportColors.taxGreen
                  : current
                      ? GstReportColors.brandGold.withValues(alpha: 0.45)
                      : GstReportColors.bodyBorder,
            ),
          ),
          child: Text(
            GstReportFormatters.shortMonth(month),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: selected ? Colors.white : color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DueDateStrip extends StatelessWidget {
  const _DueDateStrip({
    required this.filing,
    required this.stateCode,
    required this.snapshot,
    required this.workflow,
  });

  final GstFilingPeriod filing;
  final String stateCode;
  final GstReportSnapshot? snapshot;
  final GstFilingWorkflowSnapshot? workflow;

  @override
  Widget build(BuildContext context) {
    final gstr3bDue = filing.gstr3bDueDateForStateCode(stateCode);
    final monthLabel = GstReportFormatters.monthYear(filing.month);
    final monthlyStatus = workflow?.statusFor(GstFilingTask.monthlyTaxPayment);
    final iffStatus = workflow?.statusFor(GstFilingTask.b2bIffUpload);
    final quarterStatus = workflow?.statusFor(GstFilingTask.quarterReturnFiled);
    final b2bInvoices = snapshot?.gstr1B2bInvoices ?? const <GstInvoiceRow>[];
    final b2bTax = _sum(b2bInvoices, (row) => row.gstAmount);
    final monthlyAmount = monthlyStatus?.completed ?? false
        ? monthlyStatus!.amountSnapshot
        : snapshot?.dashboard.totalGst ?? 0;
    final iffAmount =
        iffStatus?.completed ?? false ? iffStatus!.amountSnapshot : b2bTax;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        final cardWidth =
            compact ? constraints.maxWidth : (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: cardWidth,
              child: filing.hasMonthlyTaxPayment
                  ? _DueCard(
                      title: 'Monthly Tax Payment',
                      date: filing.monthlyTaxPaymentDueDate,
                      icon: Icons.payments_rounded,
                      note: 'For $monthLabel PMT-06 payment',
                      amountLabel: GstReportFormatters.money(monthlyAmount),
                      completed: monthlyStatus?.completed ?? false,
                      completedAt: monthlyStatus?.completedAt,
                    )
                  : _InfoDueCard(
                      title: 'Monthly Tax Payment',
                      value: 'Not required',
                      icon: Icons.payments_rounded,
                      note:
                          '${filing.quarterLabel} close month settles through quarterly 3B',
                    ),
            ),
            SizedBox(
              width: cardWidth,
              child: filing.iffDueDate == null
                  ? const _InfoDueCard(
                      title: 'IFF B2B Window',
                      value: 'Quarter close month',
                      icon: Icons.receipt_long_rounded,
                      note: 'Use quarterly GSTR-1 final return',
                    )
                  : _DueCard(
                      title: 'IFF B2B Optional',
                      date: filing.iffDueDate!,
                      icon: Icons.receipt_long_rounded,
                      note: 'For $monthLabel B2B invoices',
                      amountLabel:
                          '${b2bInvoices.length} invoices | ${GstReportFormatters.money(iffAmount)}',
                      completed: iffStatus?.completed ?? false,
                      completedAt: iffStatus?.completedAt,
                    ),
            ),
            SizedBox(
              width: cardWidth,
              child: _DueCard(
                title: 'Quarter Final Filing',
                date: gstr3bDue,
                icon: Icons.fact_check_rounded,
                note:
                    'For ${filing.quarterLabel} ${filing.quarterRangeLabel}; GSTR-1 ${GstReportFormatters.date(filing.gstr1QuarterDueDate)}',
                amountLabel: quarterStatus?.completed ?? false
                    ? GstReportFormatters.money(quarterStatus!.amountSnapshot)
                    : 'Available in quarter closing month',
                completed: quarterStatus?.completed ?? false,
                completedAt: quarterStatus?.completedAt,
              ),
            ),
          ],
        );
      },
    );
  }

  double _sum<T>(Iterable<T> rows, double Function(T row) selector) {
    return rows.fold<double>(0, (sum, row) => sum + selector(row));
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({
    required this.title,
    required this.date,
    required this.icon,
    required this.note,
    this.amountLabel,
    this.completed = false,
    this.completedAt,
  });

  final String title;
  final DateTime date;
  final IconData icon;
  final String note;
  final String? amountLabel;
  final bool completed;
  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final status = _DueStatus.fromDate(date);
    return _DueCardShell(
      title: title,
      value: GstReportFormatters.date(date),
      badge: completed ? 'DONE' : status.label,
      color: completed ? GstReportColors.success : status.color,
      icon: icon,
      note: completed && completedAt != null
          ? '$note | Completed ${GstReportFormatters.dateTime(completedAt!)}'
          : note,
      amountLabel: amountLabel,
      completed: completed,
    );
  }
}

class _InfoDueCard extends StatelessWidget {
  const _InfoDueCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.note,
  });

  final String title;
  final String value;
  final IconData icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    return _DueCardShell(
      title: title,
      value: value,
      badge: 'INFO',
      color: GstReportColors.information,
      icon: icon,
      note: note,
      completed: false,
    );
  }
}

class _DueCardShell extends StatelessWidget {
  const _DueCardShell({
    required this.title,
    required this.value,
    required this.badge,
    required this.color,
    required this.icon,
    required this.note,
    required this.completed,
    this.amountLabel,
  });

  final String title;
  final String value;
  final String badge;
  final Color color;
  final IconData icon;
  final String note;
  final String? amountLabel;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GstReportStyles.body.copyWith(
                          color: GstReportColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      badge,
                      style: GstReportStyles.body.copyWith(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(
                    color: GstReportColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GstReportStyles.body.copyWith(fontSize: 11),
                ),
                if (amountLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    amountLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GstReportStyles.body.copyWith(
                      color: GstReportColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DueStatus {
  const _DueStatus({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  factory _DueStatus.fromDate(DateTime dueDate) {
    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateUtils.dateOnly(dueDate);
    final days = due.difference(today).inDays;
    if (days < 0) {
      return const _DueStatus(
        label: 'OVERDUE',
        color: GstReportColors.danger,
      );
    }
    if (days == 0) {
      return const _DueStatus(
        label: 'DUE TODAY',
        color: GstReportColors.warning,
      );
    }
    if (days <= 7) {
      return const _DueStatus(
        label: 'DUE SOON',
        color: GstReportColors.warning,
      );
    }
    return const _DueStatus(
      label: 'UPCOMING',
      color: GstReportColors.success,
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

class _GstPeriodPickerDialog extends StatefulWidget {
  const _GstPeriodPickerDialog({
    required this.initialMonth,
    required this.canSelectMonth,
  });

  final DateTime initialMonth;
  final bool Function(DateTime month) canSelectMonth;

  @override
  State<_GstPeriodPickerDialog> createState() => _GstPeriodPickerDialogState();
}

class _GstPeriodPickerDialogState extends State<_GstPeriodPickerDialog> {
  late int _financialYearStart;

  @override
  void initState() {
    super.initState();
    _financialYearStart =
        GstFilingPeriod.fromMonth(widget.initialMonth).financialYearStart;
  }

  @override
  Widget build(BuildContext context) {
    final filing = GstFilingPeriod.fromMonth(DateTime(_financialYearStart, 4));
    final currentFy =
        GstFilingPeriod.fromMonth(DateTime.now()).financialYearStart;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GstReportColors.taxGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: GstReportColors.taxGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select GST Filing Period',
                          style: GstReportStyles.sectionTitle,
                        ),
                        Text(
                          'Choose financial year, quarter and month.',
                          style: GstReportStyles.body.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MonthArrowButton(
                    tooltip: 'Previous financial year',
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => setState(() => _financialYearStart--),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: GstReportColors.bodySubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GstReportColors.bodyBorder),
                      ),
                      child: Text(
                        filing.financialYearLabel,
                        style: GstReportStyles.body.copyWith(
                          color: GstReportColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MonthArrowButton(
                    tooltip: 'Next financial year',
                    icon: Icons.chevron_right_rounded,
                    onPressed: _financialYearStart >= currentFy
                        ? null
                        : () => setState(() => _financialYearStart++),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DialogQuarterGrid(
                filing: filing,
                initialMonth: widget.initialMonth,
                canSelectMonth: widget.canSelectMonth,
                onSelected: (month) => Navigator.of(context).pop(month),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogQuarterGrid extends StatelessWidget {
  const _DialogQuarterGrid({
    required this.filing,
    required this.initialMonth,
    required this.canSelectMonth,
    required this.onSelected,
  });

  final GstFilingPeriod filing;
  final DateTime initialMonth;
  final bool Function(DateTime month) canSelectMonth;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final quarter in filing.financialYearQuarters)
          SizedBox(
            width: 390,
            child: _QuarterBlock(
              quarter: quarter,
              selectedMonth: DateTime(initialMonth.year, initialMonth.month),
              currentMonth: DateTime(DateTime.now().year, DateTime.now().month),
              completed: false,
              disabled: false,
              canSelectMonth: canSelectMonth,
              onMonthSelected: onSelected,
            ),
          ),
      ],
    );
  }
}

bool _sameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}
