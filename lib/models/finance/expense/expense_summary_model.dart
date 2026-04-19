// =============================================================================
// FILE        : expense_summary_model.dart
// MODULE      : Expense Entry
// LAYER       : Models
// DESCRIPTION : Aggregated expense snapshot for the left summary panel.
//               Covers total expense, category breakdown, payment-mode split,
//               daily average, and top-spending category highlight.
// =============================================================================

import 'package:intl/intl.dart';

// ── Per-category breakdown item ───────────────────────────────────────────────

class ExpenseCategoryBreakdown {
  final String categoryDbValue;
  final String label;
  final double amount;
  final String amountFormatted;
  final double percentage;    // % of total expense
  final int    count;

  const ExpenseCategoryBreakdown({
    required this.categoryDbValue,
    required this.label,
    required this.amount,
    required this.amountFormatted,
    required this.percentage,
    required this.count,
  });
}

// ── Per-payment-mode breakdown ────────────────────────────────────────────────

class ExpensePaymentBreakdown {
  final String paymentModeLabel;
  final double amount;
  final String amountFormatted;
  final int    count;

  const ExpensePaymentBreakdown({
    required this.paymentModeLabel,
    required this.amount,
    required this.amountFormatted,
    required this.count,
  });
}

// ── Main expense summary ──────────────────────────────────────────────────────

class ExpenseSummaryModel {

  final double totalExpense;
  final String totalExpenseFormatted;

  final double dailyAverage;
  final String dailyAverageFormatted;

  final int totalCount;

  final double highestSingleExpense;
  final String highestSingleFormatted;

  final String topCategoryLabel;       // Top-spending category name
  final double topCategoryAmount;
  final String topCategoryFormatted;

  final List<ExpenseCategoryBreakdown> categoryBreakdown;
  final List<ExpensePaymentBreakdown>  paymentBreakdown;

  final bool isLoading;

  const ExpenseSummaryModel({
    required this.totalExpense,
    required this.totalExpenseFormatted,
    required this.dailyAverage,
    required this.dailyAverageFormatted,
    required this.totalCount,
    required this.highestSingleExpense,
    required this.highestSingleFormatted,
    required this.topCategoryLabel,
    required this.topCategoryAmount,
    required this.topCategoryFormatted,
    required this.categoryBreakdown,
    required this.paymentBreakdown,
    this.isLoading = false,
  });

  // ── Named constructors ────────────────────────────────────────────────────

  factory ExpenseSummaryModel.zero() {
    return const ExpenseSummaryModel(
      totalExpense:           0.0,
      totalExpenseFormatted:  '₹ 0.00',
      dailyAverage:           0.0,
      dailyAverageFormatted:  '₹ 0.00',
      totalCount:             0,
      highestSingleExpense:   0.0,
      highestSingleFormatted: '₹ 0.00',
      topCategoryLabel:       '—',
      topCategoryAmount:      0.0,
      topCategoryFormatted:   '₹ 0.00',
      categoryBreakdown:      [],
      paymentBreakdown:       [],
    );
  }

  factory ExpenseSummaryModel.loading() {
    return const ExpenseSummaryModel(
      totalExpense:           0.0,
      totalExpenseFormatted:  '—',
      dailyAverage:           0.0,
      dailyAverageFormatted:  '—',
      totalCount:             0,
      highestSingleExpense:   0.0,
      highestSingleFormatted: '—',
      topCategoryLabel:       '—',
      topCategoryAmount:      0.0,
      topCategoryFormatted:   '—',
      categoryBreakdown:      [],
      paymentBreakdown:       [],
      isLoading:              true,
    );
  }

  // ── Formatter ─────────────────────────────────────────────────────────────

  static final _fmt = NumberFormat.currency(
    locale:        'en_IN',
    symbol:        '₹ ',
    decimalDigits: 2,
  );

  static String format(double v) => _fmt.format(v);
}
