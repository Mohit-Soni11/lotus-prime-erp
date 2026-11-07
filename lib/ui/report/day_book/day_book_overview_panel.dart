import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_smart_cards.dart';

/// Business activity preview, independent of Day Book navigation and exports.
class DayBookOverviewPanel extends StatelessWidget {
  const DayBookOverviewPanel({
    super.key,
    required this.summary,
    this.showDemoPreview = false,
  });

  final DayBookSummary summary;
  final bool showDemoPreview;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: DayBookStyles.panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.grid_view_rounded,
                  size: 22, color: DayBookColors.goldMetal),
              const SizedBox(width: 9),
              Expanded(
                  child: Text('Daily Overview',
                      style:
                          DayBookStyles.sectionTitle.copyWith(fontSize: 18))),
              if (showDemoPreview)
                Text('DEMO PREVIEW',
                    style: DayBookStyles.labelStrong
                        .copyWith(color: DayBookColors.warning)),
            ]),
            const SizedBox(height: 12),
            DayBookSmartCards(
              summary: summary,
              showDemoPreview: showDemoPreview,
              showPreviewNotice: false,
            ),
          ],
        ),
      );
}
