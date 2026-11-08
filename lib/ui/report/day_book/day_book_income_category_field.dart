import 'package:flutter/material.dart';

import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_form_visuals.dart';

class DayBookIncomeCategoryField extends StatefulWidget {
  const DayBookIncomeCategoryField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  State<DayBookIncomeCategoryField> createState() =>
      _DayBookIncomeCategoryFieldState();
}

class _DayBookIncomeCategoryFieldState
    extends State<DayBookIncomeCategoryField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _select(IncomeCategory category) {
    if (category == IncomeCategory.otherIncome) {
      widget.controller.clear();
      _focusNode.requestFocus();
    } else {
      widget.controller.text = category.displayLabel;
    }
  }

  @override
  Widget build(BuildContext context) => TextFormField(
        key: const ValueKey('day-book-income-category'),
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        style: DayBookStyles.labelStrong,
        decoration: DayBookFormVisuals.field(
          'Income category',
          Icons.category_outlined,
        ).copyWith(
          hintText: 'Choose or type a category',
          suffixIcon: PopupMenuButton<IncomeCategory>(
            key: const ValueKey('day-book-income-category-options'),
            tooltip: 'Choose income category',
            enabled: widget.enabled,
            icon: const Icon(Icons.arrow_drop_down_rounded,
                color: DayBookColors.goldMetal),
            onSelected: _select,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: IncomeCategory.goldRepairIncome,
                child: Text('Gold repair'),
              ),
              PopupMenuItem(
                value: IncomeCategory.silverRepairIncome,
                child: Text('Silver repair'),
              ),
              PopupMenuItem(
                value: IncomeCategory.otherIncome,
                child: Text('Other · type your own'),
              ),
            ],
          ),
        ),
        validator: (value) => (value ?? '').trim().isEmpty
            ? 'Choose or type an income category.'
            : null,
      );
}
