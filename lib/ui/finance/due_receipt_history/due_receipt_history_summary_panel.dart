import 'package:flutter/material.dart';

import '../../../logic/finance/due_receipt_history/due_receipt_history_controller.dart';
import '../../../models/finance/due_receipt_history/due_receipt_history_model.dart';
import '../../../theme/finance/due_receipt_history/due_receipt_history_theme.dart';

class DueReceiptHistorySummaryPanel extends StatelessWidget {
  final DueReceiptStatsModel stats;
  final bool isLoading;

  const DueReceiptHistorySummaryPanel({
    super.key,
    required this.stats,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryData(
        icon: DueReceiptHistoryIcons.totalCollected,
        label: DueReceiptHistoryStrings.totalCollected,
        value: DueReceiptHistoryController.formatCompact(stats.totalCollected),
        sub: 'Updated ${stats.lastRefreshedAt}',
        color: DueReceiptHistoryColors.success,
        bg: DueReceiptHistoryColors.successSoft,
      ),
      _SummaryData(
        icon: DueReceiptHistoryIcons.receipts,
        label: DueReceiptHistoryStrings.receipts,
        value: stats.receiptCount.toString(),
        sub: '${stats.dueMarkedCount} due marked',
        color: DueReceiptHistoryColors.gold,
        bg: DueReceiptHistoryColors.goldSoft,
      ),
      _SummaryData(
        icon: DueReceiptHistoryIcons.customers,
        label: DueReceiptHistoryStrings.customers,
        value: stats.customerCount.toString(),
        sub: 'Unique customers',
        color: DueReceiptHistoryColors.info,
        bg: DueReceiptHistoryColors.infoSoft,
      ),
      _SummaryData(
        icon: DueReceiptHistoryIcons.today,
        label: DueReceiptHistoryStrings.today,
        value: DueReceiptHistoryController.formatCompact(stats.todayCollected),
        sub: 'Collected today',
        color: DueReceiptHistoryColors.teal,
        bg: DueReceiptHistoryColors.tealSoft,
      ),
      _SummaryData(
        icon: DueReceiptHistoryIcons.ledgerSplit,
        label: DueReceiptHistoryStrings.ledgerSplit,
        value: DueReceiptHistoryController.formatCompact(stats.cashTotal),
        sub:
            'Bank ${DueReceiptHistoryController.formatCompact(stats.bankTotal)}',
        color: DueReceiptHistoryColors.indigo,
        bg: DueReceiptHistoryColors.indigoSoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 5
            : width >= 900
                ? 4
                : width >= 640
                    ? 3
                    : 2;
        const gap = 10.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (data) => SizedBox(
                  width: cardWidth,
                  height: 96,
                  child: _SummaryCard(data: data, isLoading: isLoading),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryData {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final Color bg;

  const _SummaryData({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.bg,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;
  final bool isLoading;

  const _SummaryCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          DueReceiptHistoryStyles.panel(color: DueReceiptHistoryColors.panelBg),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: data.color.withValues(alpha: 0.18)),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: DueReceiptHistoryStyles.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    isLoading ? '...' : data.value,
                    key: ValueKey('${data.value}-$isLoading'),
                    style: data.color == DueReceiptHistoryColors.success
                        ? DueReceiptHistoryStyles.amountSuccess
                        : DueReceiptHistoryStyles.amount
                            .copyWith(color: data.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(data.sub,
                    style: DueReceiptHistoryStyles.rowSub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
