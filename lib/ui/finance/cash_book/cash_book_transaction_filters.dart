part of 'cash_book_transaction_list.dart';

class _TopBar extends StatelessWidget {
  final CashBookController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: CashBookColors.bodyBg,
        border: Border(
          bottom: BorderSide(color: CashBookColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('MMMM yyyy').format(ctrl.activeDate)} Cash Activity',
            style: CashBookStyles.sectionTitle,
          ),
          const SizedBox(height: 4),
          Text('${ctrl.monthSummary.totalTransactions} cash transactions',
              style: CashBookStyles.labelSecondary),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MonthMetric('Opening', ctrl.monthSummary.openingBalanceStr),
              _MonthMetric('Cash In', ctrl.monthSummary.totalIncomeStr),
              _MonthMetric('Cash Out', ctrl.monthSummary.totalExpenseStr),
              _MonthMetric('Closing', ctrl.monthSummary.closingBalanceStr),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CashBookFilter.values.map((f) {
                final isActive = ctrl.filter == f;
                final label = switch (f) {
                  CashBookFilter.all => 'All',
                  CashBookFilter.incomeOnly => 'Income',
                  CashBookFilter.expenseOnly => 'Expense',
                };
                final icon = switch (f) {
                  CashBookFilter.all => CashBookIcons.filter,
                  CashBookFilter.incomeOnly => CashBookIcons.income,
                  CashBookFilter.expenseOnly => CashBookIcons.expense,
                };
                final activeColor = switch (f) {
                  CashBookFilter.incomeOnly => CashBookColors.incomeAccent,
                  CashBookFilter.expenseOnly => CashBookColors.expenseAccent,
                  _ => CashBookColors.brandGold,
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ctrl.setFilter(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeColor.withValues(alpha: 0.12)
                            : CashBookColors.summaryChipBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isActive
                              ? activeColor.withValues(alpha: 0.4)
                              : CashBookColors.bodyBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isActive
                                ? activeColor
                                : CashBookColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: CashBookColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthMetric extends StatelessWidget {
  const _MonthMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: CashBookColors.bodyPanel,
        border: Border.all(color: CashBookColors.bodyBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label  $value', style: CashBookStyles.labelSecondary),
    );
  }
}

// â”€â”€ Grouped Transaction List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
