// =============================================================================
// FILE        : cash_book_enums.dart
// MODULE      : Accounts / Cash Book
// LAYER       : Models / Enums
// DESCRIPTION : All type-safe enumerations for the Cash Book module.
//               v2 — Added Girvi categories + Other (with custom label).
//               Every enum maps to a DB string value via [dbValue] getter.
// =============================================================================

// ── 1. TRANSACTION DIRECTION ─────────────────────────────────────────────────

enum CashTransactionType {
  income('INCOME'),
  expense('EXPENSE');

  const CashTransactionType(this.dbValue);
  final String dbValue;

  static CashTransactionType fromDb(String value) =>
      CashTransactionType.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => CashTransactionType.income,
      );
}

// ── 2. INCOME CATEGORIES ─────────────────────────────────────────────────────

enum IncomeCategory {
  sale('SALE', 'Sale (POS)'),
  advanceBooking('ADVANCE', 'Advance Booking'),
  orderDelivery('ORDER_DELIVERY', 'Order Delivery'),
  girviReturn('GIRVI_RETURN', 'Girvi Released'), // ✅ v2
  loanReceived('LOAN_RECEIVED', 'Loan Received'),
  interestReceived('INTEREST_RECEIVED', 'Interest Received'),
  miscIncome('MISC_INCOME', 'Misc. Income'),
  otherIncome('OTHER_INCOME', 'Other'); // ✅ v2

  const IncomeCategory(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  /// Whether this category requires a custom label from the user
  bool get requiresCustomLabel => this == IncomeCategory.otherIncome;

  static IncomeCategory fromDb(String value) =>
      IncomeCategory.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => IncomeCategory.miscIncome,
      );
}

// ── 3. EXPENSE CATEGORIES ────────────────────────────────────────────────────

enum ExpenseCategory {
  shopRent('SHOP_RENT', 'Shop Rent'),
  staffSalary('STAFF_SALARY', 'Staff Salary'),
  electricity('ELECTRICITY', 'Electricity / Utilities'),
  purchasePayment('PURCHASE_PAYMENT', 'Purchase Payment'),
  girviGiven('GIRVI_GIVEN', 'Girvi Given'), // ✅ v2
  maintenance('MAINTENANCE', 'Maintenance & Repair'),
  advertising('ADVERTISING', 'Advertising / Marketing'),
  transport('TRANSPORT', 'Transport / Logistics'),
  bankCharges('BANK_CHARGES', 'Bank Charges'),
  governmentFees('GOVT_FEES', 'Govt. Fees / Taxes'),
  miscExpense('MISC_EXPENSE', 'Misc. Expense'),
  otherExpense('OTHER_EXPENSE', 'Other'); // ✅ v2

  const ExpenseCategory(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  /// Whether this category requires a custom label from the user
  bool get requiresCustomLabel => this == ExpenseCategory.otherExpense;

  static ExpenseCategory fromDb(String value) =>
      ExpenseCategory.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => ExpenseCategory.miscExpense,
      );
}

// ── 4. PAYMENT MODE ───────────────────────────────────────────────────────────

enum PaymentMode {
  cash('CASH', 'Cash'),
  upi('UPI', 'UPI'),
  card('CARD', 'Card'),
  bank('BANK', 'Bank Transfer'),
  cheque('CHEQUE', 'Cheque');

  const PaymentMode(this.dbValue, this.displayLabel);
  final String dbValue;
  final String displayLabel;

  static PaymentMode fromDb(String value) => PaymentMode.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => PaymentMode.cash,
      );
}

// ── 5. VIEW MODE (Date Range Toggle) ─────────────────────────────────────────

enum CashBookViewMode {
  daily,
  monthly,
  yearly,
}

// ── 6. FILTER STATE ───────────────────────────────────────────────────────────

enum CashBookFilter {
  all,
  incomeOnly,
  expenseOnly,
}

// ── 7. HELPER — Resolve display label (handles custom 'Other') ────────────────

/// Resolves the final display label for a transaction.
/// For OTHER_* categories, returns [customLabel] if present, else enum label.
String resolveDisplayLabel({
  required CashTransactionType type,
  required String categoryDbValue,
  String? customLabel,
}) {
  if (type == CashTransactionType.income) {
    final cat = IncomeCategory.fromDb(categoryDbValue);
    if (cat.requiresCustomLabel &&
        customLabel != null &&
        customLabel.isNotEmpty) {
      return customLabel;
    }
    return cat.displayLabel;
  } else {
    final cat = ExpenseCategory.fromDb(categoryDbValue);
    if (cat.requiresCustomLabel &&
        customLabel != null &&
        customLabel.isNotEmpty) {
      return customLabel;
    }
    return cat.displayLabel;
  }
}
