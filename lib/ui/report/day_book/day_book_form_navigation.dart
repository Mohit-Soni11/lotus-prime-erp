import 'package:flutter/material.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/finance/expense/expense_draft.dart';
import 'day_book_balance_dialog.dart';
import 'day_book_eod_dialog.dart';

/// Shared form routes for Day Book actions, notifications and application exit.
abstract final class DayBookFormNavigation {
  static Future<DayBookBalanceDialogResult?> verifyOpening(
    BuildContext context,
    DayBookController controller,
  ) async {
    final flow = controller.summary?.moneyFlow;
    if (flow == null) return null;
    return Navigator.of(context, rootNavigator: true)
        .push<DayBookBalanceDialogResult>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DayBookBalanceDialog(
        fullScreen: true,
        date: controller.selectedDate,
        expectedCash: flow.openingCash,
        expectedBank: flow.openingBank,
        expenseRecords: controller.summary?.expenseRecords ?? const [],
        bankAccountConfigured:
            flow.bankAccountCount != 0 || flow.openingBank.abs() >= 0.01,
        existing: controller.balanceVerification,
        onSave: controller.verifyBalance,
      ),
    ));
  }

  static Future<ExpenseDraft?> closeDay(
    BuildContext context,
    DayBookController controller,
  ) =>
      Navigator.of(context, rootNavigator: true)
          .push<ExpenseDraft>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DayBookEodDialog(
          ctrl: controller,
          fullScreen: true,
        ),
      ));
}
