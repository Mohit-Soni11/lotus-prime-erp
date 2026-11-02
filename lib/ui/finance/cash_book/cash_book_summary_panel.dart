import 'package:flutter/material.dart';

import '../../../models/finance/cash_book/cash_book_summary_model.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';

class CashBookSummaryPanel extends StatelessWidget {
  const CashBookSummaryPanel({
    super.key,
    required this.summary,
    required this.onEditOpeningBalance,
  });

  final CashBookSummaryModel summary;
  final VoidCallback onEditOpeningBalance;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Metric(
        CashBookStrings.openingBalance,
        summary.openingBalanceStr,
        'Cash at the start of this period',
        CashBookIcons.openingBalance,
        CashBookColors.brandGold,
        CashBookColors.brandGoldLight,
        onEditOpeningBalance,
      ),
      _Metric(
        CashBookStrings.totalIncome,
        summary.totalIncomeStr,
        '${summary.incomeCount} income entries',
        CashBookIcons.income,
        CashBookColors.incomeChip,
        CashBookColors.incomeBg,
        null,
      ),
      _Metric(
        CashBookStrings.totalExpense,
        summary.totalExpenseStr,
        '${summary.expenseCount} expense entries',
        CashBookIcons.expense,
        CashBookColors.expenseChip,
        CashBookColors.expenseBg,
        null,
      ),
      _Metric(
        CashBookStrings.closingBalance,
        summary.closingBalanceStr,
        summary.closingBalance < 0
            ? 'Negative cash balance — review entries'
            : 'Net movement: ${summary.netFlowStr}',
        CashBookIcons.closingBalance,
        summary.closingBalance >= 0
            ? CashBookColors.incomeText
            : CashBookColors.expenseText,
        summary.closingBalance >= 0
            ? CashBookColors.incomeBg
            : CashBookColors.expenseBg,
        null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 350
            ? 1
            : constraints.maxWidth < 1000
                ? 2
                : 4;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in cards)
              SizedBox(
                width: width,
                child: _MetricCard(metric: metric, loading: summary.isLoading),
              ),
          ],
        );
      },
    );
  }
}

class _Metric {
  const _Metric(
    this.label,
    this.value,
    this.detail,
    this.icon,
    this.accent,
    this.background,
    this.onEdit,
  );

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;
  final Color background;
  final VoidCallback? onEdit;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.loading});

  final _Metric metric;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CashBookColors.bodyPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CashBookColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
              color: CashBookColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: metric.background,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: metric.accent.withValues(alpha: 0.24)),
                ),
                child: Icon(metric.icon, size: 20, color: metric.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metric.label,
                  style: const TextStyle(
                    color: CashBookColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: metric.value,
                  child: Text(
                    loading ? '—' : metric.value,
                    style: const TextStyle(
                      color: CashBookColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (metric.onEdit != null)
                IconButton(
                  onPressed: metric.onEdit,
                  tooltip: CashBookStrings.editOpeningBalance,
                  icon: const Icon(CashBookIcons.edit, size: 17),
                  color: CashBookColors.textDark,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 28, height: 28),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            loading ? 'Loading...' : metric.detail,
            style: const TextStyle(
              color: CashBookColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
