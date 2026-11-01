import 'package:flutter/material.dart';

import '../../../models/finance/cash_book/cash_book_summary_model.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';

class CashBookBreakdownPanel extends StatelessWidget {
  const CashBookBreakdownPanel({super.key, required this.summary});

  final CashBookSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      if (summary.incomeBreakdown.isNotEmpty)
        _BreakdownSection(
          title: CashBookStrings.incomeBreakdown,
          items: summary.incomeBreakdown,
          accent: CashBookColors.incomeChip,
          background: CashBookColors.incomeBg,
        ),
      if (summary.expenseBreakdown.isNotEmpty)
        _BreakdownSection(
          title: CashBookStrings.expenseBreakdown,
          items: summary.expenseBreakdown,
          accent: CashBookColors.expenseChip,
          background: CashBookColors.expenseBg,
        ),
    ];
    if (sections.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              for (final section in sections) ...[
                section,
                if (section != sections.last) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              if (section != sections.first) const SizedBox(width: 12),
              Expanded(child: section),
            ],
          ],
        );
      },
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.items,
    required this.accent,
    required this.background,
  });

  final String title;
  final List<CategoryBreakdownItem> items;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CashBookColors.bodyPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CashBookColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: CashBookColors.textDark),
          ),
          const SizedBox(height: 14),
          for (final item in items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CashBookColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.amountFormatted,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CashBookColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (item.percentage / 100).clamp(0.0, 1.0),
                minHeight: 5,
                color: accent,
                backgroundColor: background,
              ),
            ),
            const SizedBox(height: 13),
          ],
        ],
      ),
    );
  }
}
