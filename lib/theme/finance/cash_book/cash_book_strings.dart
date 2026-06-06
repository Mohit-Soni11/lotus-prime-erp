// =============================================================================
// FILE        : cash_book_strings.dart
// MODULE      : Accounts / Cash Book
// LAYER       : Theme
// =============================================================================

class CashBookStrings {
  CashBookStrings._();

  // ── AppBar ────────────────────────────────────────────────────────────────
  static const String moduleTitle = 'Cash Book';
  static const String moduleSubtitle = 'Cash ledger and counter movement';

  // ── View Mode Labels ──────────────────────────────────────────────────────
  static const String viewDaily = 'Daily';
  static const String viewMonthly = 'Monthly';
  static const String viewYearly = 'Yearly';

  // ── Summary Panel ─────────────────────────────────────────────────────────
  static const String openingBalance = 'Opening Balance';
  static const String totalIncome = 'Total Income';
  static const String totalExpense = 'Total Expense';
  static const String closingBalance = 'Closing Balance';
  static const String netFlow = 'Net Flow';
  static const String transactions = 'Transactions';
  static const String incomeBreakdown = 'Income Breakdown';
  static const String expenseBreakdown = 'Expense Breakdown';

  // ── Transaction List ──────────────────────────────────────────────────────
  static const String noTransactions = 'No transactions found';
  static const String noTransactionsHint =
      'Add an entry or sync today\'s billing receipts.';
  static const String searchHint =
      'Search category, party, invoice, reference, or transaction ID';

  // ── Entry Dialog ──────────────────────────────────────────────────────────
  static const String addEntry = 'Add Entry';
  static const String addIncome = 'Add Income';
  static const String addExpense = 'Add Expense';
  static const String amount = 'Amount';
  static const String amountHint = 'Enter amount';
  static const String category = 'Category';
  static const String paymentMode = 'Payment Mode';
  static const String description = 'Description (Optional)';
  static const String descriptionHint = 'e.g. Monthly shop rent';
  static const String partyName = 'Party Name (Optional)';
  static const String partyHint = 'Customer / Supplier name';
  static const String date = 'Date';
  static const String saveEntry = 'Save Entry';
  static const String saving = 'Saving...';
  static const String cancel = 'Cancel';

  // ── Badges ────────────────────────────────────────────────────────────────
  static const String autoLabel = 'AUTO';

  // ── Sync ──────────────────────────────────────────────────────────────────
  static const String syncBills = 'Sync Billing Receipts';
  static const String syncSuccess = 'Bills synced successfully';
  static const String syncError = 'Sync failed. Please try again.';

  // ── Opening Balance ───────────────────────────────────────────────────────
  static const String editOpeningBalance = 'Edit Opening Balance';
  static const String openingBalanceHint = 'Enter opening cash balance';
  static const String openingBalanceSaved = 'Opening balance updated';

  // ── Void ──────────────────────────────────────────────────────────────────
  static const String voidTransaction = 'Void Transaction';
  static const String voidConfirm =
      'This transaction will be marked as voided and will not affect the balance. Proceed?';
  static const String voidSuccess = 'Transaction voided';
  static const String voidCancel = 'Keep';
  static const String voidConfirmBtn = 'Void';
}
