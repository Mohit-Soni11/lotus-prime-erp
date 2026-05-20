// =============================================================================
// FILE        : expense_icons_strings.dart
// MODULE      : Expense Entry
// LAYER       : Theme
// DESCRIPTION : All icons and string constants for the Expense Entry module.
// =============================================================================

import 'package:flutter/material.dart';

class ExpenseIcons {
  ExpenseIcons._();

  static const IconData moduleIcon = Icons.receipt_long_rounded;
  static const IconData addExpense = Icons.add_circle_rounded;
  static const IconData expense = Icons.arrow_upward_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData previous = Icons.chevron_left_rounded;
  static const IconData next = Icons.chevron_right_rounded;
  static const IconData today = Icons.today_rounded;
  static const IconData exportPdf = Icons.picture_as_pdf_rounded;
  static const IconData void_ = Icons.remove_circle_outline_rounded;
  static const IconData breakdown = Icons.bar_chart_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData edit = Icons.edit_note_rounded;

  // Payment mode icons
  static const IconData cash = Icons.payments_rounded;
  static const IconData upi = Icons.qr_code_scanner_rounded;
  static const IconData card = Icons.credit_card_rounded;
  static const IconData bank = Icons.account_balance_rounded;
  static const IconData cheque = Icons.description_rounded;

  // Category icons (for visual polish in list)
  static const IconData shopRent = Icons.store_rounded;
  static const IconData staffSalary = Icons.people_rounded;
  static const IconData electricity = Icons.electrical_services_rounded;
  static const IconData maintenance = Icons.build_rounded;
  static const IconData advertising = Icons.campaign_rounded;
  static const IconData transport = Icons.local_shipping_rounded;
  static const IconData bankCharges = Icons.account_balance_rounded;
  static const IconData governmentFees = Icons.gavel_rounded;
  static const IconData purchase = Icons.shopping_bag_rounded;
  static const IconData girvi = Icons.lock_rounded;
  static const IconData misc = Icons.category_rounded;
  static const IconData other = Icons.more_horiz_rounded;
}

class ExpenseStrings {
  ExpenseStrings._();

  static const String moduleTitle = 'Expense Entry';
  static const String moduleSubtitle = 'Track & manage shop expenses';

  static const String addExpense = 'Add Expense';
  static const String editExpense = 'Edit Expense';
  static const String voidExpense = 'Void Expense';
  static const String saveExpense = 'Save Expense';
  static const String cancel = 'Cancel';

  static const String amount = 'Amount';
  static const String amountHint = '0.00';
  static const String category = 'Category';
  static const String paymentMode = 'Payment Mode';
  static const String date = 'Date';
  static const String partyName = 'Vendor / Party Name';
  static const String partyHint = 'e.g. Sharma Electricals, Punjab Suppliers';
  static const String description = 'Description / Notes';
  static const String descriptionHint = 'Optional — any additional details';

  static const String totalExpenses = 'TOTAL EXPENSES';
  static const String thisMonth = 'THIS MONTH';
  static const String dailyAverage = 'DAILY AVG';
  static const String topCategory = 'TOP CATEGORY';
  static const String highestEntry = 'HIGHEST ENTRY';
  static const String noExpenses = 'No expenses recorded';
  static const String noExpensesHint =
      'Tap "Add Expense" to record your first entry';
  static const String searchHint = 'Search expenses…';

  static const String viewDaily = 'Day';
  static const String viewMonthly = 'Month';
  static const String viewYearly = 'Year';

  static const String categoryBreakdown = 'CATEGORY BREAKDOWN';
  static const String paymentBreakdown = 'PAYMENT MODE';

  static const String voidConfirmTitle = 'Void this expense?';
  static const String voidReasonHint = 'Reason for voiding (required)';
  static const String voidConfirm = 'Yes, Void';

  static const String saveSuccess = 'Expense saved successfully';
  static const String voidSuccess = 'Expense voided';
  static const String saveFailed = 'Failed to save — please try again';
}
