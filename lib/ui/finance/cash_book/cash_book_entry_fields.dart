part of 'cash_book_entry_dialog.dart';

class _OtherLabelField extends StatelessWidget {
  final CashBookController ctrl;
  const _OtherLabelField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: CashBookColors.brandGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('Specify Category *',
                style: CashBookStyles.labelSecondary.copyWith(
                  color: CashBookColors.brandGold,
                )),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl.customLabelCtrl,
            style: CashBookStyles.inputText,
            decoration: InputDecoration(
              hintText: 'e.g. Temple Donation, Tool Purchase, Medical',
              hintStyle: CashBookStyles.labelMuted,
              filled: true,
              fillColor: CashBookColors.brandGoldLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CashBookColors.brandGold),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: CashBookColors.brandGold.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: CashBookColors.brandGold, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Type Toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TypeToggle extends StatelessWidget {
  final CashBookController ctrl;
  const _TypeToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: CashBookColors.summaryChipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CashBookColors.bodyBorder),
      ),
      child: Row(
        children: CashTransactionType.values.map((type) {
          final isActive = ctrl.entryType == type;
          final isIncome = type == CashTransactionType.income;
          final color = isIncome
              ? CashBookColors.incomeAccent
              : CashBookColors.expenseAccent;

          return Expanded(
            child: GestureDetector(
              onTap: () => ctrl.setEntryType(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: isActive
                      ? Border.all(color: color.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isIncome ? CashBookIcons.income : CashBookIcons.expense,
                      size: 14,
                      color: isActive ? color : CashBookColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isIncome ? 'Income' : 'Expense',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? color : CashBookColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// â”€â”€ Category Dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CategoryDropdown extends StatelessWidget {
  final CashBookController ctrl;
  const _CategoryDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CashBookColors.searchBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CashBookColors.searchBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ctrl.entryCategory,
          isExpanded: true,
          style: CashBookStyles.labelPrimary,
          dropdownColor: CashBookColors.bodyPanel,
          items: ctrl.availableCategories.map((dbVal) {
            final label = ctrl.categoryLabel(dbVal, ctrl.entryType);
            final isOther = dbVal == IncomeCategory.otherIncome.dbValue ||
                dbVal == ExpenseCategory.otherExpense.dbValue;

            return DropdownMenuItem(
              value: dbVal,
              child: Row(children: [
                if (isOther) ...[
                  const Icon(Icons.edit_note_rounded,
                      size: 14, color: CashBookColors.brandGold),
                  const SizedBox(width: 6),
                ],
                Text(label, style: CashBookStyles.labelPrimary),
              ]),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) ctrl.setEntryCategory(val);
          },
        ),
      ),
    );
  }
}

// â”€â”€ Payment Mode Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
