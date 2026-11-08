import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_form_visuals.dart';

enum DayBookExpenseScope { shop, personal }

class DayBookBalanceDifferenceFields extends StatelessWidget {
  const DayBookBalanceDifferenceFields({
    super.key,
    required this.netDifference,
    required this.scope,
    required this.onScopeChanged,
    required this.category,
    required this.onCategoryChanged,
    required this.note,
    required this.readOnly,
  });

  final double netDifference;
  final DayBookExpenseScope? scope;
  final ValueChanged<DayBookExpenseScope> onScopeChanged;
  final ExpenseCategory? category;
  final ValueChanged<ExpenseCategory?> onCategoryChanged;
  final TextEditingController note;
  final bool readOnly;

  static const shopCategories = [
    ExpenseCategory.shopRent,
    ExpenseCategory.staffSalary,
    ExpenseCategory.electricity,
    ExpenseCategory.maintenance,
    ExpenseCategory.advertising,
    ExpenseCategory.transport,
    ExpenseCategory.bankCharges,
    ExpenseCategory.governmentFees,
    ExpenseCategory.miscExpense,
    ExpenseCategory.otherExpense,
  ];

  static const personalCategories = [
    ExpenseCategory.personalHousehold,
    ExpenseCategory.personalFamily,
    ExpenseCategory.personalMedical,
    ExpenseCategory.personalEducation,
    ExpenseCategory.personalTravel,
    ExpenseCategory.ownerDrawing,
  ];

  @override
  Widget build(BuildContext context) {
    if (netDifference.abs() < 0.01) return const SizedBox.shrink();
    final money =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final shortage = netDifference > 0;
    final categories = scope == DayBookExpenseScope.personal
        ? personalCategories
        : shopCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(shortage ? Icons.receipt_long_outlined : Icons.info_outline,
              color: shortage ? DayBookColors.negative : DayBookColors.warning,
              size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(shortage ? 'Expense adjustment' : 'Unrecorded excess',
                style: DayBookStyles.sectionTitle),
          ),
          Text(money.format(netDifference.abs()),
              style: DayBookStyles.value.copyWith(
                color:
                    shortage ? DayBookColors.negative : DayBookColors.warning,
              )),
        ]),
        if (shortage) ...[
          const SizedBox(height: 10),
          if (readOnly)
            Text(
              '${scope == DayBookExpenseScope.personal ? 'Personal' : 'Shop'} · ${category?.displayLabel ?? 'Unspecified'}',
              style: DayBookStyles.labelStrong,
            )
          else ...[
            SegmentedButton<DayBookExpenseScope>(
              key: const ValueKey('balance-expense-scope'),
              segments: const [
                ButtonSegment(
                    value: DayBookExpenseScope.shop,
                    label: Text('Shop expense'),
                    icon: Icon(Icons.storefront_outlined)),
                ButtonSegment(
                    value: DayBookExpenseScope.personal,
                    label: Text('Personal expense'),
                    icon: Icon(Icons.person_outline)),
              ],
              selected: scope == null ? {} : {scope!},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onScopeChanged(selection.first);
              },
            ),
            if (scope != null) ...[
              const SizedBox(height: 9),
              DropdownButtonFormField<ExpenseCategory>(
                key: ValueKey('balance-expense-category-${scope!.name}'),
                initialValue: category,
                style: DayBookStyles.labelStrong,
                decoration: DayBookFormVisuals.field(
                    'Category', Icons.category_outlined),
                items: categories
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.displayLabel,
                              style: DayBookStyles.labelStrong),
                        ))
                    .toList(),
                onChanged: onCategoryChanged,
                validator: (value) =>
                    value == null ? 'Select an expense category.' : null,
              ),
            ],
          ],
        ],
        const SizedBox(height: 9),
        TextFormField(
          key: const ValueKey('balance-expense-note'),
          controller: note,
          readOnly: readOnly,
          maxLines: 2,
          style: DayBookStyles.labelStrong,
          decoration: DayBookFormVisuals.field(
              shortage ? 'Reason / note' : 'Explain the excess',
              Icons.notes_rounded),
          validator: (value) => (value ?? '').trim().isEmpty
              ? 'Write a reason before saving.'
              : null,
        ),
      ],
    );
  }
}
