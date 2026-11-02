import 'package:flutter/material.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../logic/finance/cash_book/cash_book_history_controller.dart';
import 'cash_book_breakdown_panel.dart';
import 'cash_book_opening_balance_dialog.dart';
import 'cash_book_period_overview.dart';
import 'cash_book_date_selector.dart';
import 'cash_book_summary_panel.dart';
import 'cash_book_transaction_list.dart';
import 'cash_book_view_cards.dart';

class CashBookBody extends StatelessWidget {
  const CashBookBody({
    super.key,
    required this.ctrl,
    required this.history,
    required this.onAddEntry,
  });

  final CashBookController ctrl;
  final CashBookHistoryController history;
  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1000;
        final hasBreakdown = ctrl.summary.incomeBreakdown.isNotEmpty ||
            ctrl.summary.expenseBreakdown.isNotEmpty;
        final daily = history.view == CashBookHistoryView.daily;
        final dateSelector = CashBookDateSelector(
          controller: ctrl,
          onDateSelected: history.showDaily,
        );
        final viewCards = CashBookViewCards(controller: history);
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
                dateSelector,
                const SizedBox(height: 14),
                viewCards,
                const SizedBox(height: 16),
                if (daily) ...[
                  summary,
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                            flex: hasBreakdown ? 7 : 1, child: transactions),
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
                ] else
                  Expanded(child: CashBookPeriodOverview(controller: history)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dateSelector,
              const SizedBox(height: 12),
              viewCards,
              const SizedBox(height: 14),
              if (daily) ...[
                summary,
                const SizedBox(height: 14),
                SizedBox(height: 520, child: transactions),
                if (hasBreakdown) ...[
                  const SizedBox(height: 14),
                  CashBookBreakdownPanel(summary: ctrl.summary),
                ],
              ] else
                CashBookPeriodOverview(controller: history, shrinkWrap: true),
            ],
          ),
        );
      },
    );
  }
}
