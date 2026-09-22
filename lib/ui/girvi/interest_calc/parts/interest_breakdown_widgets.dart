part of '../interest_calc_screen.dart';

class _InterestBreakdownPanel extends StatelessWidget {
  final List<GirviInterestBreakdownLine> lines;
  final DateTime loanStartDate;
  final int totalMonths;
  final GirviElapsedPeriod elapsedPeriod;
  final double totalInterest;
  final NumberFormat moneyFmt;

  const _InterestBreakdownPanel({
    required this.lines,
    required this.loanStartDate,
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
        border: Border.all(color: GirviColors.info.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: GirviIcons.interestRate,
                color: GirviColors.info,
                dark: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interest Calculation',
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
                      'Actual Period: ${elapsedPeriod.displayLabel} | Chargeable Months: $totalMonths',
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
                label: 'Chargeable Months',
                value: totalMonths.toString(),
                color: GirviColors.success,
                wide: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < lines.length; i++) ...[
            _InterestBreakdownRow(
              line: lines[i],
              loanStartDate: loanStartDate,
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
  final DateTime loanStartDate;
  final NumberFormat moneyFmt;

  const _InterestBreakdownRow({
    required this.line,
    required this.loanStartDate,
    required this.moneyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final period = GirviInterestPeriodText.forBreakdownLine(
      loanStartDate: loanStartDate,
      line: line,
    );
    final title = period.cycleLabel;
    final subtitle =
        'Base Rs ${moneyFmt.format(line.principalBase)} | Monthly Rs ${moneyFmt.format(line.monthlyInterest)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: line.cycleNumber == 1
            ? GirviColors.info.withValues(alpha: 0.06)
            : GirviColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: line.cycleNumber == 1
              ? GirviColors.info.withValues(alpha: 0.16)
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
                  period.monthRangeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.info,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
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
      width: wide ? 188 : 118,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: GirviColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              height: 1.08,
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
        color: GirviColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GirviColors.info.withValues(alpha: 0.18)),
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
