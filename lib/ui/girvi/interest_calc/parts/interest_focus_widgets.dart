part of '../interest_calc_screen.dart';

class _CollectionFocusStrip extends StatelessWidget {
  final double interestDue;
  final double monthlyInterest;
  final int unpaidMonths;
  final double advanceAmount;
  final int advanceMonths;
  final bool settlementComplete;
  final bool isOverdue;
  final NumberFormat moneyFmt;

  const _CollectionFocusStrip({
    required this.interestDue,
    required this.monthlyInterest,
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
                    ? GirviColors.info
                    : GirviColors.success;
    final statusText = settlementComplete
        ? 'Settlement complete. Item is awaiting delivery.'
        : hasAdvance
            ? 'Advance interest credit covers about $advanceMonths month${advanceMonths == 1 ? '' : 's'}.'
            : isOverdue
                ? 'Interest collection is overdue.'
                : unpaidMonths > 0
                    ? '$unpaidMonths chargeable month${unpaidMonths == 1 ? '' : 's'} pending.'
                    : 'No chargeable interest pending.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GirviColors.cardBorder),
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
                      'Interest Collection Status',
                      maxLines: 2,
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
                      maxLines: 2,
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
                      label: 'Interest Due',
                      value: 'Rs ${moneyFmt.format(interestDue)}',
                      color: GirviColors.success,
                    ),
                    const _FocusMetric(
                      label: 'Account Status',
                      value: 'Settled',
                      color: GirviColors.success,
                    ),
                    const _FocusMetric(
                      label: 'Item Status',
                      value: 'In Shop',
                      color: GirviColors.info,
                    ),
                  ]
                : hasAdvance
                    ? [
                        _FocusMetric(
                          label: 'Interest Due',
                          value: 'Rs ${moneyFmt.format(interestDue)}',
                          color: GirviColors.success,
                        ),
                        _FocusMetric(
                          label: 'Advance Credit',
                          value: 'Rs ${moneyFmt.format(advanceAmount)}',
                          color: GirviColors.success,
                        ),
                        _FocusMetric(
                          label: 'Covered Period',
                          value:
                              '$advanceMonths month${advanceMonths == 1 ? '' : 's'}',
                          color: GirviColors.info,
                        ),
                      ]
                    : [
                        _FocusMetric(
                          label: 'Interest Due',
                          value: 'Rs ${moneyFmt.format(interestDue)}',
                          color: accent,
                          wide: true,
                        ),
                        _FocusMetric(
                          label: 'Period Due',
                          value:
                              '$unpaidMonths month${unpaidMonths == 1 ? '' : 's'}',
                          color: accent,
                        ),
                        _FocusMetric(
                          label: 'Monthly Interest',
                          value: 'Rs ${moneyFmt.format(monthlyInterest)}',
                          color: GirviColors.brandGold,
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
              SizedBox(width: 300, child: leading),
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
    final danger = color == GirviColors.danger;
    final textColor = danger ? GirviColors.danger : GirviColors.textDark;

    return Container(
      width: wide ? 260 : 190,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: danger ? GirviColors.dangerBg : GirviColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color:
              danger ? GirviColors.dangerBorder : color.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: textColor,
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
                color: textColor,
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
