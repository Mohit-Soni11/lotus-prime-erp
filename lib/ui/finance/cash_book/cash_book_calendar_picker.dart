import 'package:flutter/material.dart';

import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';

class CashBookCalendarPicker {
  CashBookCalendarPicker._();

  static Future<void> selectDay(
      BuildContext context, CashBookController controller,
      {VoidCallback? onSelected}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate:
          controller.activeDate.isAfter(today) ? today : controller.activeDate,
      firstDate: DateTime(1),
      lastDate: today,
      helpText: 'Select cash ledger date',
      builder: _theme,
    );
    if (selected != null && context.mounted) {
      controller.selectDate(selected);
      onSelected?.call();
    }
  }

  static Widget _theme(BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: CashBookColors.brandGold,
            onPrimary: Colors.white,
            surface: CashBookColors.bodyPanel,
            onSurface: CashBookColors.textDark,
          ),
          dialogTheme:
              const DialogThemeData(backgroundColor: CashBookColors.bodyPanel),
        ),
        child: child!,
      );
}
