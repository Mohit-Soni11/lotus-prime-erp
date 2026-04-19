// =============================================================================
// FILE        : bank_book_summary_model.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : Models
// DESCRIPTION : Aggregated financial snapshot for the Bank Book left panel.
//               Covers opening balance, total credit, total debit,
//               closing balance, reconciliation status, and cheque summary.
//
// CA ALIGNMENT:
//   Closing Balance = Opening Balance + Total Credits - Total Debits
//   Reconciled Balance = only cleared/reconciled transactions
// =============================================================================

import 'package:intl/intl.dart';
import 'bank_book_enums.dart';

// ── Per-category line in breakdown panel ──────────────────────────────────────

class BankCategoryBreakdownItem {
  final String               label;
  final String               categoryDbValue;
  final BankTransactionType  type;
  final double               amount;
  final String               amountFormatted;
  final double               percentage;
  final int                  count;

  const BankCategoryBreakdownItem({
    required this.label,
    required this.categoryDbValue,
    required this.type,
    required this.amount,
    required this.amountFormatted,
    required this.percentage,
    required this.count,
  });
}

// ── Cheque Summary ────────────────────────────────────────────────────────────

class ChequeSummary {
  final int    totalIssued;
  final int    totalCleared;
  final int    totalBounced;
  final int    totalPending;
  final double pendingAmount;
  final String pendingAmountFormatted;

  const ChequeSummary({
    required this.totalIssued,
    required this.totalCleared,
    required this.totalBounced,
    required this.totalPending,
    required this.pendingAmount,
    required this.pendingAmountFormatted,
  });

  factory ChequeSummary.zero() => const ChequeSummary(
    totalIssued:            0,
    totalCleared:           0,
    totalBounced:           0,
    totalPending:           0,
    pendingAmount:          0,
    pendingAmountFormatted: '₹ 0.00',
  );
}

// ── Main Summary Snapshot ─────────────────────────────────────────────────────

class BankBookSummaryModel {

  final double openingBalance;
  final double totalCredit;
  final double totalDebit;
  final double closingBalance;
  final double netFlow;

  final String openingBalanceStr;
  final String totalCreditStr;
  final String totalDebitStr;
  final String closingBalanceStr;
  final String netFlowStr;

  final List<BankCategoryBreakdownItem> creditBreakdown;
  final List<BankCategoryBreakdownItem> debitBreakdown;

  final int    totalTransactions;
  final int    creditCount;
  final int    debitCount;
  final int    reconciledCount;
  final int    unreconciledCount;

  final ChequeSummary chequeSummary;

  final bool isLoading;

  const BankBookSummaryModel({
    required this.openingBalance,
    required this.totalCredit,
    required this.totalDebit,
    required this.closingBalance,
    required this.netFlow,
    required this.openingBalanceStr,
    required this.totalCreditStr,
    required this.totalDebitStr,
    required this.closingBalanceStr,
    required this.netFlowStr,
    required this.creditBreakdown,
    required this.debitBreakdown,
    required this.totalTransactions,
    required this.creditCount,
    required this.debitCount,
    required this.reconciledCount,
    required this.unreconciledCount,
    required this.chequeSummary,
    this.isLoading = false,
  });

  bool get isPositive => netFlow >= 0;

  // ── Factory: Loading ──────────────────────────────────────────────────────
  factory BankBookSummaryModel.loading() => BankBookSummaryModel(
    openingBalance:    0,
    totalCredit:       0,
    totalDebit:        0,
    closingBalance:    0,
    netFlow:           0,
    openingBalanceStr: '--',
    totalCreditStr:    '--',
    totalDebitStr:     '--',
    closingBalanceStr: '--',
    netFlowStr:        '--',
    creditBreakdown:   [],
    debitBreakdown:    [],
    totalTransactions: 0,
    creditCount:       0,
    debitCount:        0,
    reconciledCount:   0,
    unreconciledCount: 0,
    chequeSummary:     ChequeSummary.zero(),
    isLoading:         true,
  );

  // ── Factory: Zero ─────────────────────────────────────────────────────────
  factory BankBookSummaryModel.zero() => BankBookSummaryModel(
    openingBalance:    0,
    totalCredit:       0,
    totalDebit:        0,
    closingBalance:    0,
    netFlow:           0,
    openingBalanceStr: _fmt(0),
    totalCreditStr:    _fmt(0),
    totalDebitStr:     _fmt(0),
    closingBalanceStr: _fmt(0),
    netFlowStr:        _fmt(0),
    creditBreakdown:   [],
    debitBreakdown:    [],
    totalTransactions: 0,
    creditCount:       0,
    debitCount:        0,
    reconciledCount:   0,
    unreconciledCount: 0,
    chequeSummary:     ChequeSummary.zero(),
  );

  static final _currencyFmt = NumberFormat.currency(
    locale:        'en_IN',
    symbol:        '₹ ',
    decimalDigits: 2,
  );

  static String _fmt(double v) => _currencyFmt.format(v);
}