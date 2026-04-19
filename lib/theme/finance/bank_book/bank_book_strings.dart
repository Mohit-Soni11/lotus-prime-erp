// =============================================================================
// FILE        : bank_book_strings.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : Theme
// =============================================================================

class BankBookStrings {
  BankBookStrings._();

  // ── AppBar ─────────────────────────────────────────────────────────────────
  static const String moduleTitle    = 'Bank Book';
  static const String moduleSubtitle = 'Bank Account Ledger';

  // ── View Mode ──────────────────────────────────────────────────────────────
  static const String viewDaily   = 'Daily';
  static const String viewMonthly = 'Monthly';
  static const String viewYearly  = 'Yearly';

  // ── Accounts ───────────────────────────────────────────────────────────────
  static const String noAccountsTitle   = 'No Bank Account Added';
  static const String noAccountsHint    = 'Add your first bank account to start tracking.';
  static const String addAccount        = 'Add Account';
  static const String editAccount       = 'Edit Account';
  static const String primaryBadge      = 'PRIMARY';
  static const String setPrimary        = 'Set as Primary';

  // ── Summary Panel ──────────────────────────────────────────────────────────
  static const String openingBalance    = 'Opening Balance';
  static const String totalCredit       = 'Total Credit';
  static const String totalDebit        = 'Total Debit';
  static const String closingBalance    = 'Closing Balance';
  static const String netFlow           = 'Net Flow';
  static const String transactions      = 'Transactions';
  static const String creditBreakdown   = 'Credit Breakdown';
  static const String debitBreakdown    = 'Debit Breakdown';
  static const String reconciliationStatus = 'Reconciliation';
  static const String reconciled        = 'Reconciled';
  static const String unreconciled      = 'Unreconciled';

  // ── Cheque Summary ─────────────────────────────────────────────────────────
  static const String chequeSummary     = 'Cheque Summary';
  static const String chequeIssued      = 'Issued';
  static const String chequeCleared     = 'Cleared';
  static const String chequeBounced     = 'Bounced';
  static const String chequePending     = 'Pending';
  static const String pendingAmount     = 'Pending Amount';

  // ── Transaction List ───────────────────────────────────────────────────────
  static const String noTransactions     = 'No transactions found';
  static const String noTransactionsHint = 'Add your first entry using the + button above.';
  static const String searchHint         = 'Search by category, party, cheque no or TXN ID…';

  // ── Entry Dialog ───────────────────────────────────────────────────────────
  static const String addEntry          = 'Add Entry';
  static const String addCredit         = 'Add Credit';
  static const String addDebit          = 'Add Debit';
  static const String amount            = 'Amount (₹)';
  static const String amountHint        = 'Enter amount';
  static const String category          = 'Category';
  static const String paymentMode       = 'Payment Mode';
  static const String description       = 'Description (Optional)';
  static const String descriptionHint   = 'e.g. Supplier payment for gold purchase';
  static const String partyName         = 'Party Name (Optional)';
  static const String partyHint         = 'Customer / Supplier name';
  static const String date              = 'Transaction Date';
  static const String valueDate         = 'Value Date (Clearing Date)';
  static const String chequeNumber      = 'Cheque Number';
  static const String chequeNumberHint  = 'Enter cheque number';
  static const String chequeDate        = 'Cheque Date';
  static const String chequeStatusLabel = 'Cheque Status';
  static const String saveEntry         = 'Save Entry';
  static const String saving            = 'Saving…';
  static const String cancel            = 'Cancel';

  // ── Add Account Dialog ─────────────────────────────────────────────────────
  static const String accountName     = 'Account Name *';
  static const String accountNameHint = 'e.g. SBI Current Account';
  static const String bankName        = 'Bank Name *';
  static const String bankNameHint    = 'e.g. State Bank of India';
  static const String accountNumber   = 'Account Number *';
  static const String ifscCode        = 'IFSC Code';
  static const String branchName      = 'Branch Name';
  static const String holderName      = 'Account Holder Name';
  static const String upiId           = 'UPI ID';
  static const String accountType     = 'Account Type';
  static const String openingBal      = 'Opening Balance (₹)';
  static const String openingBalHint  = 'Current balance when added to ERP';
  static const String saveAccount     = 'Save Account';

  // ── Badges ─────────────────────────────────────────────────────────────────
  static const String autoLabel       = 'AUTO';
  static const String reconciledLabel = 'RECONCILED';

  // ── Actions ────────────────────────────────────────────────────────────────
  static const String syncBills       = 'Sync Today\'s Bills';
  static const String syncSuccess     = 'Bills synced successfully';
  static const String markReconciled  = 'Mark as Reconciled';
  static const String updateCheque    = 'Update Cheque Status';

  // ── Opening Balance ────────────────────────────────────────────────────────
  static const String editOpeningBalance  = 'Edit Opening Balance';
  static const String openingBalanceHint  = 'Enter current bank balance';
  static const String openingBalanceSaved = 'Opening balance updated';

  // ── Void ───────────────────────────────────────────────────────────────────
  static const String voidTransaction  = 'Void Transaction';
  static const String voidConfirm      = 'This transaction will be marked as voided. Proceed?';
  static const String voidSuccess      = 'Transaction voided';
  static const String voidCancel       = 'Keep';
  static const String voidConfirmBtn   = 'Void';
}