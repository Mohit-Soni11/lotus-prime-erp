import 'package:flutter/material.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import 'cash_book_breakdown_panel.dart';
import 'cash_book_opening_balance_dialog.dart';
import 'cash_book_period_bar.dart';
import 'cash_book_summary_panel.dart';
import 'cash_book_transaction_list.dart';

class CashBookBody extends StatelessWidget {
  const CashBookBody({
    super.key,
    required this.ctrl,
    required this.onAddEntry,
  });

  final CashBookController ctrl;
  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1000;
        final hasBreakdown = ctrl.summary.incomeBreakdown.isNotEmpty ||
            ctrl.summary.expenseBreakdown.isNotEmpty;
        final periodBar = CashBookPeriodBar(ctrl: ctrl);
        final summary = CashBookSummaryPanel(
          summary: ctrl.summary,
          onEditOpeningBalance: () =>
              showCashBookOpeningBalanceDialog(context, ctrl),
        );
        final transactions = CashBookTransactionList(
          ctrl: ctrl,
          onAddEntry: onAddEntry,
        );

        if (desktop) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                periodBar,
                const SizedBox(height: 14),
                summary,
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: hasBreakdown ? 7 : 1, child: transactions),
                      if (hasBreakdown) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child:
                                CashBookBreakdownPanel(summary: ctrl.summary),
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              periodBar,
              const SizedBox(height: 12),
              summary,
              const SizedBox(height: 14),
              SizedBox(height: 520, child: transactions),
              if (hasBreakdown) ...[
                const SizedBox(height: 14),
                CashBookBreakdownPanel(summary: ctrl.summary),
              ],
            ],
          ),
        );
      },
    );
  }
}
