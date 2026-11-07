import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import 'day_book_position_panels.dart';
import 'day_book_money_panel.dart';

class DayBookPrimaryGrid extends StatelessWidget {
  const DayBookPrimaryGrid({
    super.key,
    required this.summary,
    this.onAddCashIncome,
    this.onSetBalance,
    this.showBalanceAction = false,
    this.balanceSaved = false,
  });

  final DayBookSummary summary;
  final VoidCallback? onAddCashIncome;
  final VoidCallback? onSetBalance;
  final bool showBalanceAction;
  final bool balanceSaved;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final position = DayBookPositionPanels(
            summary: summary,
            onSetBalance: onSetBalance,
            showBalanceAction: showBalanceAction,
            balanceSaved: balanceSaved,
          );
          final flow = summary.moneyFlow;
          if (flow == null) return position;

          final movement = DayBookMoneyPanel(
            flow: flow,
            onAddCashIncome: onAddCashIncome,
          );
          if (constraints.maxWidth < 1550) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [movement, const SizedBox(height: 16), position],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: movement),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: position),
            ],
          );
        },
      );
}
