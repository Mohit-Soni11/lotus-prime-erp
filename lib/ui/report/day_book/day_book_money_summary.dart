import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_money_flow.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookMoneySummary extends StatelessWidget {
  const DayBookMoneySummary({super.key, required this.flow});

  final DayBookMoneyFlow flow;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryMetric(
          'Opening Balance',
          flow.openingTotal,
          DayBookIcons.openingBalance,
          DayBookColors.information,
          DayBookColors.informationSoft,
          DayBookColors.informationBorder),
      _SummaryMetric(
          'Money In',
          flow.moneyIn,
          DayBookIcons.cashIn,
          DayBookColors.positive,
          DayBookColors.positiveSoft,
          DayBookColors.positiveBorder),
      _SummaryMetric(
          'Money Out',
          flow.moneyOut,
          DayBookIcons.cashOut,
          DayBookColors.negative,
          DayBookColors.negativeSoft,
          DayBookColors.negativeBorder),
      _SummaryMetric(
          'Closing Balance',
          flow.closingTotal,
          DayBookIcons.closingBalance,
          DayBookColors.warning,
          DayBookColors.warningSoft,
          DayBookColors.warningBorder),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: DayBookColors.brandGold,
              borderRadius: BorderRadius.circular(3),
            )),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Money Movement',
              style: DayBookStyles.sectionTitle.copyWith(fontSize: 19)),
          Text('Posted cash and bank movements for the selected day.',
              style: DayBookStyles.sectionSubtitle.copyWith(fontSize: 11)),
        ])),
      ]),
      const SizedBox(height: 13),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 510
                ? 2
                : 1;
        const gap = 9.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final item in items)
            SizedBox(width: width, child: _SummaryCard(metric: item)),
        ]);
      }),
    ]);
  }
}

class _SummaryMetric {
  const _SummaryMetric(this.label, this.amount, this.icon, this.color,
      this.background, this.border);

  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.metric});

  final _SummaryMetric metric;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: DayBookStyles.softPanel(
          color: metric.background,
          borderColor: metric.border,
        ),
        child: Row(children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(metric.icon, size: 19, color: metric.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.labelStrong.copyWith(fontSize: 10.5)),
              const SizedBox(height: 2),
              Text(
                  NumberFormat.currency(
                          locale: 'en_IN', symbol: '₹', decimalDigits: 2)
                      .format(metric.amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DayBookStyles.valueLarge.copyWith(fontSize: 16)),
            ]),
          ),
        ]),
      );
}
