// =============================================================================
// FILE        : cash_book_strings.dart
// MODULE      : Accounts / Cash Book
// LAYER       : Theme
// =============================================================================

class CashBookStrings {
  CashBookStrings._();

  // ── AppBar ────────────────────────────────────────────────────────────────
  static const String moduleTitle = 'Account Book';
  static const String moduleSubtitle = 'Cash account activity';

  // ── View Mode Labels ──────────────────────────────────────────────────────
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
      'Cash sales, collections and expenses appear here automatically.';
  static const String searchHint =
      'Search category, party, invoice, reference, amount, or transaction ID';

  // ── Entry Dialog ──────────────────────────────────────────────────────────
  static const String addEntry = 'Add Cash Income';
  static const String addIncome = 'Add Extra Cash Income';
  static const String amount = 'Amount';
  static const String amountHint = 'Enter amount';
  static const String category = 'Category';
  static const String paymentMode = 'Payment Mode';
  static const String description = 'Reason for cash received *';
  static const String descriptionHint = 'Reason for cash received';
  static const String partyName = 'Party Name (Optional)';
  static const String partyHint = 'Received from';
  static const String date = 'Date';
  static const String saveEntry = 'Save Entry';
  static const String saving = 'Saving...';
  static const String cancel = 'Cancel';

  // ── Badges ────────────────────────────────────────────────────────────────
  static const String autoLabel = 'AUTO';

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
