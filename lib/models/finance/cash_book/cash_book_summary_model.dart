// =============================================================================
// FILE        : cash_book_summary_model.dart
// MODULE      : Accounts / Cash Book
// LAYER       : Models
// DESCRIPTION : Aggregated financial snapshot for the left summary panel.
//               Covers opening balance, total income, total expense,
//               closing balance, and per-category breakdowns.
// =============================================================================

import 'package:intl/intl.dart';
import 'cash_book_enums.dart';

// ── Per-category line in the breakdown panel ──────────────────────────────────

class CategoryBreakdownItem {
  final String label;
  final String categoryDbValue;
  final CashTransactionType type;
  final double amount;
  final String amountFormatted;
  final double percentage; // % of total income or expense

  const CategoryBreakdownItem({
    required this.label,
    required this.categoryDbValue,
    required this.type,
    required this.amount,
    required this.amountFormatted,
    required this.percentage,
  });
}

// ── Main summary snapshot ─────────────────────────────────────────────────────

class CashBookSummaryModel {
  final double openingBalance;
  final double totalIncome;
  final double totalExpense;
  final double closingBalance;
  final double netFlow; // income - expense

  final String openingBalanceStr;
  final String totalIncomeStr;
  final String totalExpenseStr;
  final String closingBalanceStr;
  final String netFlowStr;

  final List<CategoryBreakdownItem> incomeBreakdown;
  final List<CategoryBreakdownItem> expenseBreakdown;

  final int totalTransactions;
  final int incomeCount;
  final int expenseCount;

  final bool isLoading;

  const CashBookSummaryModel({
    required this.openingBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.closingBalance,
    required this.netFlow,
    required this.openingBalanceStr,
    required this.totalIncomeStr,
    required this.totalExpenseStr,
    required this.closingBalanceStr,
    required this.netFlowStr,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.totalTransactions,
    required this.incomeCount,
    required this.expenseCount,
    this.isLoading = false,
  });

  bool get isPositive => netFlow >= 0;

  // ── Factory: Loading placeholder ─────────────────────────────────────────

  factory CashBookSummaryModel.loading() => const CashBookSummaryModel(
        openingBalance: 0,
        totalIncome: 0,
        totalExpense: 0,
        closingBalance: 0,
        netFlow: 0,
        openingBalanceStr: '--',
        totalIncomeStr: '--',
        totalExpenseStr: '--',
        closingBalanceStr: '--',
        netFlowStr: '--',
        incomeBreakdown: [],
        expenseBreakdown: [],
        totalTransactions: 0,
        incomeCount: 0,
        expenseCount: 0,
        isLoading: true,
      );

  // ── Factory: Zero state ───────────────────────────────────────────────────

  factory CashBookSummaryModel.zero() => CashBookSummaryModel(
        openingBalance: 0,
        totalIncome: 0,
        totalExpense: 0,
        closingBalance: 0,
        netFlow: 0,
        openingBalanceStr: _fmt(0),
        totalIncomeStr: _fmt(0),
        totalExpenseStr: _fmt(0),
        closingBalanceStr: _fmt(0),
        netFlowStr: _fmt(0),
        incomeBreakdown: [],
        expenseBreakdown: [],
        totalTransactions: 0,
        incomeCount: 0,
        expenseCount: 0,
      );

  // ── Formatter ─────────────────────────────────────────────────────────────

  static final _currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );

  static String _fmt(double v) => _currencyFmt.format(v);
}
