import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_demo_preview.dart';
import '../../../models/reports/day_book/day_book_models.dart';
import '../../../models/reports/day_book/day_book_smart_summary.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_activity_card.dart';

class DayBookSmartCards extends StatelessWidget {
  const DayBookSmartCards({
    super.key,
    required this.summary,
    this.showDemoPreview = false,
    this.showPreviewNotice = true,
  });

  final DayBookSummary summary;
  final bool showDemoPreview;
  final bool showPreviewNotice;

  @override
  Widget build(BuildContext context) {
    final visibleSummary =
        showDemoPreview ? DayBookDemoPreview.forDate(summary.date) : summary;
    final cards = DayBookSmartSummary.fromDay(visibleSummary).cards;
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
          if (showDemoPreview && showPreviewNotice) ...[
            const _DemoPreviewNotice(),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in cards)
                SizedBox(
                  width: cardWidth,
                  child: DayBookActivityCard(
                    card: card,
                    isDemo: showDemoPreview,
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}

class _DemoPreviewNotice extends StatelessWidget {
  const _DemoPreviewNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: DayBookStyles.softPanel(
          color: DayBookColors.brandGoldSoft,
          borderColor: DayBookColors.brandGoldBorder,
        ),
        child: Row(children: [
          const Icon(Icons.visibility_outlined,
              size: 16, color: DayBookColors.textPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'DEMO PREVIEW · Sample activity and amounts for UI review',
              style: DayBookStyles.labelStrong
                  .copyWith(fontSize: 11.5, color: DayBookColors.textPrimary),
            ),
          ),
        ]),
      );
}
