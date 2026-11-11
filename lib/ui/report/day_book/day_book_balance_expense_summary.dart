import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_expense_record.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookBalanceExpenseSummary extends StatelessWidget {
  const DayBookBalanceExpenseSummary({
    super.key,
    required this.records,
  });

  final List<DayBookExpenseRecord> records;

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(0, (sum, record) => sum + record.amount);
    final formatted =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(total);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: DayBookStyles.softPanel(
        color: DayBookColors.bodySubtle,
        borderColor: DayBookColors.bodyBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_outlined,
                color: DayBookColors.goldMetal, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Text("Today's Expenses Paid",
                  style: DayBookStyles.sectionTitle.copyWith(fontSize: 16)),
            ),
            Text(formatted, style: DayBookStyles.value.copyWith(fontSize: 17)),
          ]),
          const SizedBox(height: 5),
          Text(
            '${records.length} expense ${records.length == 1 ? 'entry' : 'entries'} · Already included in posted Money Out; opening comparison is unchanged.',
            style: DayBookStyles.labelStrong.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
