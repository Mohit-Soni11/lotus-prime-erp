part of '../../screens/customer_metal_checkout_report_screen.dart';

class _YearMonth {
  final int year;
  final int month;

  const _YearMonth(this.year, this.month);
}

class _CheckoutPeriodPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final List<int> availableYears;
  final List<_CheckoutMonthSummary> Function(int year) monthlySummariesFor;
  final int Function(int year) fallbackMonthForYear;

  const _CheckoutPeriodPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.availableYears,
    required this.monthlySummariesFor,
    required this.fallbackMonthForYear,
  });

  @override
  State<_CheckoutPeriodPickerDialog> createState() =>
      _CheckoutPeriodPickerDialogState();
}

class _CheckoutPeriodPickerDialogState
    extends State<_CheckoutPeriodPickerDialog> {
  late int _draftYear;
  late int _draftMonth;

  @override
  void initState() {
    super.initState();
    _draftYear = widget.initialYear;
    _draftMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final summaries = widget.monthlySummariesFor(_draftYear);
    final selectedSummary = summaries.firstWhere(
      (summary) => summary.month == _draftMonth,
      orElse: () =>
          _CheckoutMonthSummary(month: _draftMonth, entries: const []),
    );

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, minWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PeriodPickerHeader(
                year: _draftYear,
                month: _draftMonth,
                summary: selectedSummary,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _YearRail(
                          availableYears: widget.availableYears,
                          selectedYear: _draftYear,
                          onYearSelected: _selectYear,
                        ),
                        const SizedBox(height: 14),
                        _MonthSelectorGrid(
                          selectedMonth: _draftMonth,
                          summaries: summaries,
                          onMonthSelected: _selectMonth,
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 180,
                        child: _YearRail(
                          availableYears: widget.availableYears,
                          selectedYear: _draftYear,
                          onYearSelected: _selectYear,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MonthSelectorGrid(
                          selectedMonth: _draftMonth,
                          summaries: summaries,
                          onMonthSelected: _selectMonth,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectYear(int year) {
    setState(() {
      _draftYear = year;
      _draftMonth = widget.fallbackMonthForYear(year);
    });
  }

  void _selectMonth(int month) {
    Navigator.pop(context, _YearMonth(_draftYear, month));
  }
}

class _PeriodPickerHeader extends StatelessWidget {
  final int year;
  final int month;
  final _CheckoutMonthSummary summary;
  final VoidCallback onClose;

  const _PeriodPickerHeader({
    required this.year,
    required this.month,
    required this.summary,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.22),
            ),
          ),
          child: const Icon(
            Icons.event_note_rounded,
            color: PurchaseEntryColors.purchaseAccent,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Checkout Report Period', style: _titleStyle),
              const SizedBox(height: 4),
              Text(
                '${_monthName(month)} $year | ${summary.lineCount} checkout lines | ${summary.batchCount} batches',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _subtitleStyle,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          style: IconButton.styleFrom(
            fixedSize: const Size(38, 38),
            minimumSize: const Size(38, 38),
            backgroundColor: const Color(0xFFF8FAFC),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}

class _YearRail extends StatelessWidget {
  final List<int> availableYears;
  final int selectedYear;
  final ValueChanged<int> onYearSelected;

  const _YearRail({
    required this.availableYears,
    required this.selectedYear,
    required this.onYearSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 392),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text('Calendar Year', style: _metricLabelStyle),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              shrinkWrap: true,
              itemCount: availableYears.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final year = availableYears[index];
                return _YearOptionButton(
                  year: year,
                  selected: year == selectedYear,
                  onTap: () => onYearSelected(year),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YearOptionButton extends StatelessWidget {
  final int year;
  final bool selected;
  final VoidCallback onTap;

  const _YearOptionButton({
    required this.year,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF8E1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? PurchaseEntryColors.purchaseAccent
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$year',
                  style: _buttonTextStyle.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: PurchaseEntryColors.purchaseAccent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSelectorGrid extends StatelessWidget {
  final int selectedMonth;
  final List<_CheckoutMonthSummary> summaries;
  final ValueChanged<int> onMonthSelected;

  const _MonthSelectorGrid({
    required this.selectedMonth,
    required this.summaries,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 460
                ? 3
                : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final summary in summaries)
              _MonthButton(
                width: width,
                summary: summary,
                selected: summary.month == selectedMonth,
                onTap: () => onMonthSelected(summary.month),
              ),
          ],
        );
      },
    );
  }
}

class _MonthButton extends StatelessWidget {
  final double width;
  final _CheckoutMonthSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const _MonthButton({
    required this.width,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = summary.hasData;
    final accent = selected
        ? PurchaseEntryColors.purchaseAccent
        : active
            ? const Color(0xFF0F766E)
            : const Color(0xFF9CA3AF);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFFFF8E1)
                  : active
                      ? const Color(0xFFF0FDFA)
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? accent
                    : active
                        ? const Color(0xFF99F6E4)
                        : const Color(0xFFD8D2C8),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? 0.08 : 0.04),
                  blurRadius: selected ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _monthShortName(summary.month),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _cardTitleStyle,
                      ),
                    ),
                    Icon(
                      active
                          ? Icons.local_fire_department_rounded
                          : Icons.calendar_today_rounded,
                      color: accent,
                      size: 19,
                    ),
                  ],
                ),
                Text(
                  active
                      ? '${summary.lineCount} lines | ${summary.batchCount} batches'
                      : 'No checkout data',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _cardSubTitleStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
