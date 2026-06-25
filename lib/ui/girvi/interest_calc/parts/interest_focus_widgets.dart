part of '../interest_calc_screen.dart';

class _CollectionFocusStrip extends StatelessWidget {
  final double interestDue;
  final double monthlyInterest;
  final double totalPayable;
  final int unpaidMonths;
  final double advanceAmount;
  final int advanceMonths;
  final bool settlementComplete;
  final bool isOverdue;
  final NumberFormat moneyFmt;

  const _CollectionFocusStrip({
    required this.interestDue,
    required this.monthlyInterest,
    required this.totalPayable,
    required this.unpaidMonths,
    required this.advanceAmount,
    required this.advanceMonths,
    required this.settlementComplete,
    required this.isOverdue,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final hasAdvance = advanceMonths > 0 && !settlementComplete;
    final accent = settlementComplete
        ? GirviColors.success
        : hasAdvance
            ? GirviColors.success
            : isOverdue
                ? GirviColors.danger
                : unpaidMonths > 0
                    ? GirviColors.warning
                    : GirviColors.success;
    final statusText = settlementComplete
        ? 'Settlement complete - item awaiting delivery'
        : hasAdvance
            ? 'Advance credit about $advanceMonths month${advanceMonths == 1 ? '' : 's'}'
            : isOverdue
                ? 'Overdue'
                : unpaidMonths > 0
                    ? '$unpaidMonths month${unpaidMonths == 1 ? '' : 's'} due'
                    : 'No month due';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final leading = Row(
            children: [
              _IconBox(
                  icon: GirviIcons.interestRate, color: accent, dark: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection Focus',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 9,
            runSpacing: 9,
            children: settlementComplete
                ? [
                    _FocusMetric(
                      label: 'Due Now',
                      value: 'Rs ${moneyFmt.format(interestDue)}',
                      color: GirviColors.success,
                    ),
                    _FocusMetric(
                      label: 'Excess Received',
                      value: 'Rs ${moneyFmt.format(advanceAmount)}',
                      color: advanceAmount > 0
                          ? GirviColors.danger
                          : GirviColors.success,
                      wide: true,
                    ),
                    const _FocusMetric(
                      label: 'Custody',
                      value: 'In Shop',
                      color: GirviColors.info,
                    ),
                    _FocusMetric(
                      label: 'Total Payable',
                      value: 'Rs ${moneyFmt.format(totalPayable)}',
                      color: GirviColors.success,
                      wide: true,
                    ),
                  ]
                : hasAdvance
                    ? [
                        _FocusMetric(
                          label: 'Due Now',
                          value: 'Rs ${moneyFmt.format(interestDue)}',
                          color: GirviColors.success,
                        ),
                        _FocusMetric(
                          label: 'Advance Credit',
                          value: 'Rs ${moneyFmt.format(advanceAmount)}',
                          color: GirviColors.success,
                          wide: true,
                        ),
                        _FocusMetric(
                          label: 'Advance Months',
                          value:
                              '$advanceMonths month${advanceMonths == 1 ? '' : 's'}',
                          color: GirviColors.info,
                        ),
                        _FocusMetric(
                          label: 'Monthly Interest',
                          value: 'Rs ${moneyFmt.format(monthlyInterest)}',
                          color: GirviColors.brandGold,
                          wide: true,
                        ),
                      ]
                    : [
                        _FocusMetric(
                          label: 'Due Now',
                          value: 'Rs ${moneyFmt.format(interestDue)}',
                          color: accent,
                          wide: true,
                        ),
                        _FocusMetric(
                          label: 'Months Due',
                          value:
                              '$unpaidMonths month${unpaidMonths == 1 ? '' : 's'}',
                          color: accent,
                        ),
                        _FocusMetric(
                          label: 'Monthly Interest',
                          value: 'Rs ${moneyFmt.format(monthlyInterest)}',
                          color: GirviColors.info,
                          wide: true,
                        ),
                        _FocusMetric(
                          label: 'Total Payable',
                          value: 'Rs ${moneyFmt.format(totalPayable)}',
                          color: GirviColors.purple,
                          wide: true,
                        ),
                      ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leading,
                const SizedBox(height: 12),
                metrics,
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 250, child: leading),
              const SizedBox(width: 12),
              Expanded(child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _FocusMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _FocusMetric({
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 198 : 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestBreakdownPanel extends StatelessWidget {
  final List<GirviInterestBreakdownLine> lines;
  final int totalMonths;
  final GirviElapsedPeriod elapsedPeriod;
  final double totalInterest;
  final NumberFormat moneyFmt;

  const _InterestBreakdownPanel({
    required this.lines,
    required this.totalMonths,
    required this.elapsedPeriod,
    required this.totalInterest,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.warning.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: GirviIcons.interestRate,
                color: GirviColors.warning,
                dark: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interest Breakdown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Actual ${elapsedPeriod.displayLabel} | Chargeable $totalMonths month${totalMonths == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _BreakdownTotalPill(
                label: 'Total Interest',
                value: 'Rs ${moneyFmt.format(totalInterest)}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _BreakdownPeriodChip(
                label: 'Years',
                value: elapsedPeriod.years.toString(),
                color: GirviColors.purple,
              ),
              _BreakdownPeriodChip(
                label: 'Months',
                value: elapsedPeriod.months.toString(),
                color: GirviColors.info,
              ),
              _BreakdownPeriodChip(
                label: 'Days',
                value: elapsedPeriod.days.toString(),
                color: GirviColors.warning,
              ),
              _BreakdownPeriodChip(
                label: 'Chargeable',
                value: '$totalMonths mo',
                color: GirviColors.success,
                wide: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < lines.length; i++) ...[
            _InterestBreakdownRow(
              line: lines[i],
              moneyFmt: moneyFmt,
            ),
            if (i != lines.length - 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _InterestBreakdownRow extends StatelessWidget {
  final GirviInterestBreakdownLine line;
  final NumberFormat moneyFmt;

  const _InterestBreakdownRow({
    required this.line,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final title = line.cycleNumber == 1
        ? 'First ${line.months} month${line.months == 1 ? '' : 's'}'
        : 'After ${GirviLoanModel.compoundCycleMonths * (line.cycleNumber - 1)} months - ${line.months} month${line.months == 1 ? '' : 's'}';
    final subtitle =
        'Base Rs ${moneyFmt.format(line.principalBase)} | Monthly Rs ${moneyFmt.format(line.monthlyInterest)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: line.cycleNumber == 1
            ? GirviColors.warning.withValues(alpha: 0.08)
            : GirviColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: line.cycleNumber == 1
              ? GirviColors.warning.withValues(alpha: 0.20)
              : GirviColors.info.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          _CountBadge(value: line.cycleNumber.toString().padLeft(2, '0')),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (line.capitalizedAfterLine) ...[
            const SizedBox(width: 10),
            const _TinyTag(
              label: 'Capitalized',
              color: GirviColors.purple,
            ),
          ],
          const SizedBox(width: 12),
          Text(
            'Rs ${moneyFmt.format(line.interestAmount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownPeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _BreakdownPeriodChip({
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 150 : 112,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownTotalPill extends StatelessWidget {
  final String label;
  final String value;

  const _BreakdownTotalPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GirviColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GirviColors.warning.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
