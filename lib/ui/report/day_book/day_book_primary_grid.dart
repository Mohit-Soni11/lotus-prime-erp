import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import 'day_book_money_panel.dart';
import 'day_book_sections.dart';

class DayBookPrimaryGrid extends StatelessWidget {
  const DayBookPrimaryGrid({super.key, required this.summary});

  final DayBookSummary summary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final position = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DayBookOpeningPosition(summary: summary),
              const SizedBox(height: 16),
              DayBookClosingPosition(summary: summary),
            ],
          );
          final flow = summary.moneyFlow;
          if (flow == null) return position;

          final movement = DayBookMoneyPanel(flow: flow);
          if (constraints.maxWidth < 1350) {
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
