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
        sub: 'For the current view',
        color: DueReceiptHistoryColors.success,
        bg: DueReceiptHistoryColors.successSoft,
      ),
      _SummaryData(
        icon: DueReceiptHistoryIcons.receipts,
        label: DueReceiptHistoryStrings.receipts,
        value: stats.receiptCount.toString(),
        sub: 'Payment entries',
        color: DueReceiptHistoryColors.gold,
        bg: DueReceiptHistoryColors.goldSoft,
      ),
      _SummaryData(
        icon: DueReceiptHistoryIcons.customers,
        label: DueReceiptHistoryStrings.customers,
        value: stats.customerCount.toString(),
        sub: 'Customers with receipts',
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
        label: DueReceiptHistoryStrings.cashCollected,
        value: DueReceiptHistoryController.formatCompact(stats.cashTotal),
        sub:
            'Bank: ${DueReceiptHistoryController.formatCompact(stats.bankTotal)}',
        color: DueReceiptHistoryColors.indigo,
        bg: DueReceiptHistoryColors.indigoSoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1400
            ? 5
            : width >= 900
                ? 3
                : width >= 340
                    ? 2
                    : 1;
        const gap = 12.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (data) => SizedBox(
                  width: cardWidth,
                  height: 130,
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
      padding: const EdgeInsets.all(16),
      decoration:
          DueReceiptHistoryStyles.panel(color: DueReceiptHistoryColors.panelBg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: data.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: data.color.withValues(alpha: 0.2)),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.label,
                  style: DueReceiptHistoryStyles.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DueReceiptHistoryColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Tooltip(
            message: data.value,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                isLoading ? '—' : data.value,
                key: ValueKey('${data.label}:${data.value}:$isLoading'),
                style: DueReceiptHistoryStyles.amount.copyWith(fontSize: 22),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isLoading ? 'Loading...' : data.sub,
            style: DueReceiptHistoryStyles.label.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
