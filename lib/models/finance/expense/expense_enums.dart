// =============================================================================
// FILE        : expense_enums.dart
// MODULE      : Expense Entry
// LAYER       : Models / Enums
// DESCRIPTION : All type-safe enumerations for the Expense Entry module.
//               Uses existing ExpenseCategory & PaymentMode from Cash Book.
//               Adds Expense-module-specific view/filter enums.
// =============================================================================

// ── 1. VIEW MODE (Date Range Toggle) ─────────────────────────────────────────

enum ExpenseViewMode {
  daily,
  monthly,
  yearly,
}

// ── 2. FILTER (Category-based quick filter) ───────────────────────────────────

enum ExpenseFilter {
  all,
  shopRent,
  staffSalary,
  electricity,
  maintenance,
  advertising,
  transport,
  bankCharges,
  governmentFees,
  miscExpense,
  other,
}

extension ExpenseFilterExt on ExpenseFilter {
  String get displayLabel => switch (this) {
    ExpenseFilter.all            => 'All Categories',
    ExpenseFilter.shopRent       => 'Shop Rent',
    ExpenseFilter.staffSalary    => 'Staff Salary',
    ExpenseFilter.electricity    => 'Electricity',
    ExpenseFilter.maintenance    => 'Maintenance',
    ExpenseFilter.advertising    => 'Advertising',
    ExpenseFilter.transport      => 'Transport',
    ExpenseFilter.bankCharges    => 'Bank Charges',
    ExpenseFilter.governmentFees => 'Govt. Fees',
    ExpenseFilter.miscExpense    => 'Misc. Expense',
    ExpenseFilter.other          => 'Other',
  };

  /// Maps filter to DB category value (null = no category filter = 'all')
  String? get dbCategory => switch (this) {
    ExpenseFilter.all            => null,
    ExpenseFilter.shopRent       => 'SHOP_RENT',
    ExpenseFilter.staffSalary    => 'STAFF_SALARY',
    ExpenseFilter.electricity    => 'ELECTRICITY',
    ExpenseFilter.maintenance    => 'MAINTENANCE',
    ExpenseFilter.advertising    => 'ADVERTISING',
    ExpenseFilter.transport      => 'TRANSPORT',
    ExpenseFilter.bankCharges    => 'BANK_CHARGES',
    ExpenseFilter.governmentFees => 'GOVT_FEES',
    ExpenseFilter.miscExpense    => 'MISC_EXPENSE',
    ExpenseFilter.other          => 'OTHER_EXPENSE',
  };
}

// ── 3. SORT ORDER ─────────────────────────────────────────────────────────────

enum ExpenseSortOrder {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
}

extension ExpenseSortOrderExt on ExpenseSortOrder {
  String get displayLabel => switch (this) {
    ExpenseSortOrder.dateDesc   => 'Newest First',
    ExpenseSortOrder.dateAsc    => 'Oldest First',
    ExpenseSortOrder.amountDesc => 'Highest Amount',
    ExpenseSortOrder.amountAsc  => 'Lowest Amount',
  };
}
