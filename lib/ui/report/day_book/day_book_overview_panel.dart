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
            LayoutBuilder(builder: (context, constraints) {
              final inline = constraints.maxWidth >= 760;
              final title = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view_rounded,
                      size: 19, color: DayBookColors.goldMetal),
                  const SizedBox(width: 9),
                  Text(
                    'Daily Overview',
                    style: DayBookStyles.sectionTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: DayBookColors.textPrimary,
                    ),
                  ),
                ],
              );
              final subtitle = Text(
                showDemoPreview
                    ? 'DEMO PREVIEW · Smart summary of the selected day. Click any card to view details.'
                    : 'Smart summary of the selected day. Click any card to view details.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: inline ? TextAlign.right : TextAlign.left,
                style: DayBookStyles.label.copyWith(
                  fontSize: 11,
                  color: DayBookColors.textSecondary,
                ),
              );
              if (inline) {
                return Row(children: [
                  title,
                  const SizedBox(width: 12),
                  Expanded(child: subtitle),
                ]);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 5),
                  subtitle,
                ],
              );
            }),
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
