// =============================================================================
// FILE        : bank_book_enums.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : Models / Enums
// DESCRIPTION : All type-safe enumerations for the Bank Book module.
//               Every enum exposes a [dbValue] for serialisation and a
//               [displayLabel] for UI rendering. No magic strings anywhere.
//
// CA / LEGAL ALIGNMENT:
//   • Credit/Debit terminology matches bank passbook standard
//   • Cheque lifecycle matches Indian banking norms
//   • Categories align with Schedule VI accounting heads
// =============================================================================

// ── 1. TRANSACTION DIRECTION ──────────────────────────────────────────────────

enum BankTransactionType {
  credit('CREDIT', 'Credit'),
  debit('DEBIT', 'Debit');

  const BankTransactionType(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  static BankTransactionType fromDb(String value) =>
      BankTransactionType.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => BankTransactionType.credit,
      );
}

// ── 2. CREDIT CATEGORIES (Money Coming IN to Bank) ────────────────────────────

enum BankCreditCategory {
  salePayment('SALE_PAYMENT', 'Sale Payment'),
  dueCollection('DUE_COLLECTION', 'Due Collection'),
  advanceReceived('ADVANCE_RECEIVED', 'Advance Received'),
  orderDelivery('ORDER_DELIVERY', 'Order Delivery Payment'),
  chequeDeposit('CHEQUE_DEPOSIT', 'Cheque Deposit'),
  cashDeposit('CASH_DEPOSIT', 'Cash Deposit'),
  loanReceived('LOAN_RECEIVED', 'Loan Received'),
  interestReceived('INTEREST_RECEIVED', 'Interest Received'),
  refundReceived('REFUND_RECEIVED', 'Refund Received'),
  accountTransferIn('TRANSFER_IN', 'Account Transfer In'),
  miscCredit('MISC_CREDIT', 'Misc. Credit');

  const BankCreditCategory(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  static BankCreditCategory fromDb(String value) =>
      BankCreditCategory.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => BankCreditCategory.miscCredit,
      );
}

// ── 3. DEBIT CATEGORIES (Money Going OUT from Bank) ───────────────────────────

enum BankDebitCategory {
  supplierPayment('SUPPLIER_PAYMENT', 'Supplier Payment'),
  purchasePayment('PURCHASE_PAYMENT', 'Purchase Payment'),
  staffSalary('STAFF_SALARY', 'Staff Salary'),
  shopRent('SHOP_RENT', 'Shop Rent'),
  electricity('ELECTRICITY', 'Electricity / Utilities'),
  gstPayment('GST_PAYMENT', 'GST / Tax Payment'),
  bankCharges('BANK_CHARGES', 'Bank Charges / Fees'),
  loanRepayment('LOAN_REPAYMENT', 'Loan Repayment'),
  cashWithdrawal('CASH_WITHDRAWAL', 'Cash Withdrawal'),
  accountTransferOut('TRANSFER_OUT', 'Account Transfer Out'),
  advertising('ADVERTISING', 'Advertising / Marketing'),
  maintenance('MAINTENANCE', 'Maintenance & Repair'),
  transport('TRANSPORT', 'Transport / Logistics'),
  insurance('INSURANCE', 'Insurance Premium'),
  chequeBounced('CHEQUE_BOUNCED', 'Cheque Bounced'),
  miscDebit('MISC_DEBIT', 'Misc. Debit');

  const BankDebitCategory(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  static BankDebitCategory fromDb(String value) =>
      BankDebitCategory.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => BankDebitCategory.miscDebit,
      );
}

// ── 4. PAYMENT MODE ────────────────────────────────────────────────────────────

enum BankPaymentMode {
  neft('NEFT', 'NEFT'),
  rtgs('RTGS', 'RTGS'),
  imps('IMPS', 'IMPS'),
  upi('UPI', 'UPI'),
  cheque('CHEQUE', 'Cheque'),
  cashDeposit('CASH_DEPOSIT', 'Cash Deposit'),
  cashWithdrawal('CASH_WITHDRAWAL', 'Cash Withdrawal'),
  card('CARD', 'Debit / Credit Card'),
  autoDebit('AUTO_DEBIT', 'Auto Debit / ECS');

  const BankPaymentMode(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  static BankPaymentMode fromDb(String value) =>
      BankPaymentMode.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => BankPaymentMode.neft,
      );
}

// ── 5. BANK ACCOUNT TYPE ──────────────────────────────────────────────────────

enum BankAccountType {
  current('CURRENT', 'Current Account'),
  savings('SAVINGS', 'Savings Account'),
  overdraft('OD', 'Overdraft Account'),
  cc('CC', 'Cash Credit Account');

  const BankAccountType(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  static BankAccountType fromDb(String value) =>
      BankAccountType.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => BankAccountType.current,
      );
}

// ── 6. CHEQUE STATUS ──────────────────────────────────────────────────────────

enum ChequeStatus {
  issued('ISSUED', 'Issued'),
  presented('PRESENTED', 'Presented to Bank'),
  cleared('CLEARED', 'Cleared'),
  bounced('BOUNCED', 'Bounced / Returned');

  const ChequeStatus(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  static ChequeStatus fromDb(String value) => ChequeStatus.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => ChequeStatus.issued,
      );
}

// ── 7. VIEW MODE ──────────────────────────────────────────────────────────────

enum BankBookViewMode {
  daily,
  monthly,
  yearly,
}

// ── 8. FILTER ─────────────────────────────────────────────────────────────────

enum BankBookFilter {
  all,
  creditOnly,
  debitOnly,
  chequeOnly,
  pendingReconciliation,
}
