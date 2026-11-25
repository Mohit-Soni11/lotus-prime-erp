import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/finance/expense/expense_draft.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';

class DayBookShortageActionButton extends StatelessWidget {
  const DayBookShortageActionButton({
    super.key,
    required this.draft,
    required this.onPressed,
  });

  final ExpenseDraft draft;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cash = draft.paymentMode == PaymentMode.cash;
    final account = cash ? 'Cash' : 'Bank';
    final amount = NumberFormat.currency(locale: 'en_IN', symbol: '₹')
        .format(draft.amount);
    return Tooltip(
      message: 'Open Expense Entry for $account shortage of $amount',
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(
          cash ? Icons.payments_outlined : Icons.account_balance_outlined,
          size: 18,
        ),
        label: Text('$account Shortage'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 17),
          backgroundColor: DayBookColors.brandGold,
          foregroundColor: DayBookColors.textPrimary,
          disabledBackgroundColor: DayBookColors.brandGoldSoft,
          disabledForegroundColor: DayBookColors.goldMetal,
          side: const BorderSide(color: DayBookColors.brandGoldBorder),
          elevation: 2,
          textStyle: DayBookStyles.button.copyWith(fontSize: 14),
        ),
      ),
    );
  }
}
