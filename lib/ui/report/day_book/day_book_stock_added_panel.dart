import 'package:flutter/material.dart';

import '../../../models/reports/day_book/day_book_models.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_smart_format.dart';
import 'day_book_stock_added_row.dart';

class DayBookStockAddedPanel extends StatelessWidget {
  const DayBookStockAddedPanel({
    super.key,
    required this.summary,
  });

  final DayBookSummary summary;

  @override
  Widget build(BuildContext context) {
    final entries = summary.stockAddedBatches;
    final totalValue =
        entries.fold<double>(0, (total, batch) => total + batch.purchaseValue);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
      decoration: DayBookStyles.panel(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final title = Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: DayBookColors.brandGoldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: DayBookColors.goldMetal, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock Added Today',
                        style:
                            DayBookStyles.sectionTitle.copyWith(fontSize: 18)),
                  ]),
            ),
          ]);
          final summary = _SummaryBadge(
            count: entries.length,
            totalValue: totalValue,
          );
          return compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  title,
                  const SizedBox(height: 10),
                  summary,
                ])
              : Row(children: [Expanded(child: title), summary]);
        }),
        const SizedBox(height: 11),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 23),
            child: Text('No Add Stock batch was posted on this day.',
                textAlign: TextAlign.center, style: DayBookStyles.label),
          )
        else
          ListView.separated(
            itemCount: entries.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) => DayBookStockAddedRow(
              batch: entries[index],
            ),
          ),
      ]),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.count,
    required this.totalValue,
  });

  final int count;
  final double totalValue;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DayBookColors.brandGoldSoft,
          border: Border.all(color: DayBookColors.brandGoldBorder),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 9,
          runSpacing: 4,
          children: [
            const Icon(Icons.layers_outlined,
                color: DayBookColors.goldMetal, size: 16),
            Text('$count ${count == 1 ? 'Batch' : 'Batches'}',
                style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
            Text('│', style: DayBookStyles.label),
            Text('Purchase Value',
                style: DayBookStyles.label.copyWith(fontSize: 13)),
            Text(dayBookSmartMoney(totalValue),
                style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
          ],
        ),
      );
}
