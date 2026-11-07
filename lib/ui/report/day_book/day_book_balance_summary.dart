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
    final actual = complete ? actualCash! + actualBank! : null;
    final variance =
        complete ? ((actual! - expected) * 100).roundToDouble() / 100 : null;
    final cashMismatch = complete && (actualCash! - expectedCash).abs() >= 0.01;
    final bankMismatch = complete && (actualBank! - expectedBank).abs() >= 0.01;
    final componentsMatch = !cashMismatch && !bankMismatch;
    final varianceColor = componentsMatch
        ? DayBookColors.positive
        : variance != null && variance < 0
            ? DayBookColors.negative
            : DayBookColors.warning;

    return Container(
      key: const ValueKey('combined-opening-summary'),
      padding: const EdgeInsets.all(14),
      decoration: DayBookStyles.softPanel(
        color: DayBookColors.brandGoldSoft,
        borderColor: DayBookColors.brandGoldBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: DayBookColors.goldMetal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Combined Opening · Cash + Bank',
                  style: DayBookStyles.sectionTitle),
            ),
          ]),
          const SizedBox(height: 10),
          _amountRow('Expected', money.format(expected)),
          _amountRow('Actual',
              actual == null ? 'Enter cash and bank' : money.format(actual)),
          const Divider(height: 16, color: DayBookColors.brandGoldBorder),
          _amountRow(
            'Total difference',
            variance == null ? '—' : money.format(variance),
            color: variance == null ? null : varianceColor,
          ),
          if (complete && variance!.abs() < 0.01 && !componentsMatch) ...[
            const SizedBox(height: 7),
            Text(
              'Total matches, but cash and bank differences offset each other. Review both separately.',
              style: DayBookStyles.labelStrong
                  .copyWith(color: DayBookColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label, style: DayBookStyles.labelStrong)),
          Text(
            value,
            style: DayBookStyles.value.copyWith(color: color),
            textAlign: TextAlign.right,
          ),
        ]),
      );
}
