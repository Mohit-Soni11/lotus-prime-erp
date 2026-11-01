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
          // Search field
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: CashBookColors.searchBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CashBookColors.searchBorder),
            ),
            child: TextField(
              controller: ctrl.searchCtrl,
              style: CashBookStyles.labelPrimary,
              decoration: InputDecoration(
                hintText: CashBookStrings.searchHint,
                hintStyle: CashBookStyles.labelMuted,
                prefixIcon: const Icon(CashBookIcons.search,
                    size: 18, color: CashBookColors.searchIcon),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter chips
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

// â”€â”€ Grouped Transaction List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
