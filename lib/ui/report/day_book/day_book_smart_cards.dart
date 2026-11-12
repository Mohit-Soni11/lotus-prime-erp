import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_smart_summary.dart';
import 'day_book_activity_card.dart';

class DayBookSmartCards extends StatelessWidget {
  const DayBookSmartCards({
    super.key,
    required this.summary,
  });

  final DayBookSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = DayBookSmartSummary.fromDay(summary).cards;
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 10.0;
      final width = constraints.maxWidth;
      final columns = width >= 1050
          ? 4
          : width >= 840
              ? 3
              : width >= 560
                  ? 2
                  : 1;
      final cardWidth = (width - gap * (columns - 1)) / columns;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in cards)
                SizedBox(
                  width: cardWidth,
                  child: DayBookActivityCard(
                    card: card,
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
