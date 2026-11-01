import 'package:flutter/material.dart';

import '../../../logic/finance/due_collection_entry/due_collection_entry_controller.dart';
import '../../../models/finance/due_collection_entry/due_collection_entry_model.dart';
import '../../../theme/finance/due_collection_entry/due_collection_entry_theme.dart';

class DueCollectionSummary extends StatelessWidget {
  const DueCollectionSummary(
      {super.key, required this.stats, required this.isLoading});

  final DueCollectionStatsModel stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryMetric(
        'Total Due',
        DueCollectionEntryController.formatAmount(stats.totalDue),
        DueCollectionEntryIcons.amount,
        DueCollectionEntryColors.danger,
        DueCollectionEntryColors.dangerBg,
      ),
      _SummaryMetric(
        'Due Bills',
        stats.billCount.toString(),
        DueCollectionEntryIcons.bill,
        DueCollectionEntryColors.info,
        DueCollectionEntryColors.infoBg,
      ),
      _SummaryMetric(
        'Due Customers',
        stats.customerCount.toString(),
        DueCollectionEntryIcons.customer,
        const Color(0xFF008D70),
        DueCollectionEntryColors.successBg,
      ),
      _SummaryMetric(
        'Overdue Amount',
        DueCollectionEntryController.formatAmount(stats.overdueDue),
        DueCollectionEntryIcons.warning,
        const Color(0xFFC87800),
        DueCollectionEntryColors.warningBg,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 410
            ? 1
            : constraints.maxWidth < 960
                ? 2
                : 4;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                  width: width,
                  child: _SummaryCard(metric: card, isLoading: isLoading)),
          ],
        );
      },
    );
  }
}

class _SummaryMetric {
  const _SummaryMetric(
      this.label, this.value, this.icon, this.accent, this.background);

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.metric, required this.isLoading});

  final _SummaryMetric metric;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: DueCollectionEntryStyles.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: metric.background,
                  borderRadius: BorderRadius.circular(9),
                  border:
                      Border.all(color: metric.accent.withValues(alpha: 0.24)),
                ),
                child: Icon(metric.icon, color: metric.accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metric.label,
                  style: DueCollectionEntryStyles.label
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            isLoading ? '—' : metric.value,
            style: DueCollectionEntryStyles.amount.copyWith(fontSize: 22),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
