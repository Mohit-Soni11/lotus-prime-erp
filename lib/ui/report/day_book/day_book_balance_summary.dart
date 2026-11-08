import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookBalanceSummary extends StatelessWidget {
  const DayBookBalanceSummary({
    super.key,
    required this.expectedCash,
    required this.expectedBank,
    required this.actualCash,
    required this.actualBank,
  });

  final double expectedCash;
  final double expectedBank;
  final double? actualCash;
  final double? actualBank;

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final expected = expectedCash + expectedBank;
    final complete = actualCash != null && actualBank != null;
    final counted = complete ? actualCash! + actualBank! : null;
    final difference = complete ? _round(expected - counted!) : null;
    final modesMatch = complete &&
        _round(expectedCash - actualCash!).abs() < 0.01 &&
        _round(expectedBank - actualBank!).abs() < 0.01;
    final mismatch = complete && !modesMatch;

    return Container(
      key: const ValueKey('combined-opening-summary'),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: DayBookColors.bodySubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DayBookColors.bodyBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.fact_check_outlined,
              color: DayBookColors.goldMetal, size: 20),
          const SizedBox(width: 9),
          Text('Verification Summary',
              style: DayBookStyles.sectionTitle
                  .copyWith(fontSize: 16, color: DayBookColors.goldMetal)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              DayBookColors.bodyPanel,
              mismatch
                  ? DayBookColors.negativeSoft
                  : DayBookColors.brandGoldSoft,
            ]),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: mismatch
                    ? DayBookColors.negativeBorder
                    : DayBookColors.bodyBorder),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final system =
                _metric('System Opening', 'Expected', money.format(expected));
            final countedMetric = _metric('Counted Opening', 'Cash + Bank',
                counted == null ? '—' : money.format(counted));
            final result = _result(
              money: money,
              complete: complete,
              difference: difference,
              modesMatch: modesMatch,
            );
            if (constraints.maxWidth < 500) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  system,
                  const Divider(height: 15),
                  countedMetric,
                  const Divider(height: 15),
                  result,
                ],
              );
            }
            return Row(children: [
              Expanded(flex: 10, child: system),
              const SizedBox(height: 62, child: VerticalDivider(width: 16)),
              Expanded(flex: 10, child: countedMetric),
              const SizedBox(height: 62, child: VerticalDivider(width: 16)),
              Expanded(flex: 12, child: result),
            ]);
          }),
        ),
        if (complete)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              '${money.format(expected)} − ${money.format(counted)}',
              key: const ValueKey('opening-balance-subtraction'),
              textAlign: TextAlign.right,
              style: DayBookStyles.labelStrong
                  .copyWith(fontSize: 13, color: DayBookColors.textPrimary),
            ),
          ),
      ]),
    );
  }

  static double _round(double amount) => (amount * 100).roundToDouble() / 100;

  Widget _metric(String title, String subtitle, String amount) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: DayBookStyles.labelStrong
                  .copyWith(fontSize: 13, color: DayBookColors.textPrimary)),
          Text(subtitle,
              style: DayBookStyles.labelStrong
                  .copyWith(fontSize: 12, color: DayBookColors.textPrimary)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount,
                style: DayBookStyles.valueLarge.copyWith(fontSize: 18)),
          ),
        ],
      );

  Widget _result({
    required NumberFormat money,
    required bool complete,
    required double? difference,
    required bool modesMatch,
  }) {
    final differs = difference != null && difference.abs() >= 0.01;
    final color = differs
        ? DayBookColors.negative
        : modesMatch
            ? DayBookColors.positive
            : DayBookColors.warning;
    final title = differs ? 'Difference' : 'Status';
    final subtitle = differs ? 'Expected − counted' : 'Cash + Bank';
    final value = !complete
        ? '—'
        : differs
            ? money.format(difference.abs())
            : modesMatch
                ? 'Verified'
                : 'Review';
    final badge = !complete
        ? 'Pending'
        : modesMatch
            ? 'Matched'
            : 'Mismatch';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: DayBookStyles.labelStrong
              .copyWith(fontSize: 13, color: DayBookColors.textPrimary)),
      Text(subtitle,
          style: DayBookStyles.labelStrong
              .copyWith(fontSize: 12, color: DayBookColors.textPrimary)),
      const SizedBox(height: 5),
      Row(children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: DayBookStyles.valueLarge
                    .copyWith(fontSize: 18, color: color)),
          ),
        ),
        const SizedBox(width: 6),
        _statusBadge(badge, color),
      ]),
    ]);
  }

  Widget _statusBadge(String badge, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.19)),
        ),
        child: Text(badge,
            style:
                DayBookStyles.labelStrong.copyWith(fontSize: 12, color: color)),
      );
}
