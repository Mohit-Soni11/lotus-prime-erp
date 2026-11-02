import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import 'cash_book_calendar_picker.dart';

class CashBookDateSelector extends StatelessWidget {
  const CashBookDateSelector({
    super.key,
    required this.controller,
    this.onDateSelected,
  });

  final CashBookController controller;
  final VoidCallback? onDateSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => CashBookCalendarPicker.selectDay(
        context,
        controller,
        onSelected: onDateSelected,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CashBookColors.bodyPanel,
          border: Border.all(
            color: CashBookColors.brandGold.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_rounded,
                color: CashBookColors.brandGold, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cash Ledger Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: CashBookColors.textDark,
                ),
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(controller.activeDate),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: CashBookColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
