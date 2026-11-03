import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/reports/day_book/day_book_expense_classification.dart';
import '../../../models/reports/day_book/day_book_money_flow.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookExpensePanel extends StatelessWidget {
  const DayBookExpensePanel({super.key, required this.flow});

  final DayBookMoneyFlow flow;

  @override
  Widget build(BuildContext context) {
    final totals = DayBookExpenseClassification.totals(flow);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'INR ');
    final operating = totals[DayBookOutflowPurpose.operations] ?? 0;
    return Container(
      decoration: DayBookStyles.panel(),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text('Expenses & Other Payments',
            style: DayBookStyles.sectionTitle),
        subtitle: Text(
          'Operating expenses ${currency.format(operating)} · other outflows shown separately',
          style: DayBookStyles.sectionSubtitle,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final purpose in DayBookOutflowPurpose.values)
            if ((totals[purpose] ?? 0) != 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          Text(purpose.label, style: DayBookStyles.labelStrong),
                    ),
                    Text(currency.format(totals[purpose]),
                        style: DayBookStyles.value),
                  ],
                ),
              ),
          if (totals.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('No posted payments for this day.',
                  style: DayBookStyles.label),
            ),
        ],
      ),
    );
  }
}
