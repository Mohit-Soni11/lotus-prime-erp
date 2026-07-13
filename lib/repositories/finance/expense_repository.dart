// =============================================================================
// FILE        : expense_repository.dart
// MODULE      : Expense Entry
// LAYER       : Repository / Data Access
// DESCRIPTION : All DB read/write operations for the Expense Entry module.
//               Reads/writes to CashTransactions table (type = 'EXPENSE').
//               Single source of truth — data auto-reflected in Cash Book.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/finance/cash_book/cash_book_enums.dart';
import '../../models/finance/expense/expense_model.dart';
import '../../models/finance/expense/expense_summary_model.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class ExpenseRepository {
  final AppDatabase _db;
  ExpenseRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ── Currency formatter ────────────────────────────────────────────────────
  static final _fmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );
  static String _f(double v) => _fmt.format(v);

  // ==========================================================================
  // 1. WATCH EXPENSES — Live stream for a date range
  // ==========================================================================

  Stream<List<ExpenseModel>> watchExpenses({
    required DateTime from,
    required DateTime to,
  }) {
    return (_db.select(_db.cashTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.type.equals(CashTransactionType.expense.dbValue))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
          ..where((t) => t.txnDate.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.txnDate)]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  // ==========================================================================
  // 2. FETCH EXPENSES — One-shot with optional category & search filter
  // ==========================================================================

  Future<List<ExpenseModel>> fetchExpenses({
    required DateTime from,
    required DateTime to,
    String? categoryDbValue, // null = all categories
    String? searchQuery,
  }) async {
    try {
      var query = _db.select(_db.cashTransactions)
        ..where((t) => t.isVoided.equals(false))
        ..where((t) => t.type.equals(CashTransactionType.expense.dbValue))
        ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
        ..where((t) => t.txnDate.isSmallerOrEqualValue(to));

      if (categoryDbValue != null) {
        query = query..where((t) => t.category.equals(categoryDbValue));
      }

      final rows =
          await (query..orderBy([(t) => OrderingTerm.desc(t.txnDate)])).get();

      var models = rows.map(_rowToModel).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        models = models.where((m) {
          return m.categoryLabel.toLowerCase().contains(q) ||
              (m.partyName?.toLowerCase().contains(q) ?? false) ||
              (m.description?.toLowerCase().contains(q) ?? false) ||
              (m.customLabel?.toLowerCase().contains(q) ?? false) ||
              m.expenseId.toLowerCase().contains(q);
        }).toList();
      }

      return models;
    } catch (e) {
      AppLogger.debug('❌ ExpenseRepository.fetchExpenses: $e');
      return [];
    }
  }

  // ==========================================================================
  // 3. COMPUTE SUMMARY — Aggregated stats for left panel
  // ==========================================================================

  Future<ExpenseSummaryModel> computeSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) => t.isVoided.equals(false))
            ..where((t) => t.type.equals(CashTransactionType.expense.dbValue))
            ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
            ..where((t) => t.txnDate.isSmallerOrEqualValue(to)))
          .get();

      if (rows.isEmpty) return ExpenseSummaryModel.zero();

      double totalExpense = 0.0;
      double highestSingle = 0.0;
      final Map<String, double> byCategory = {};
      final Map<String, double> byMode = {};
      final Map<String, int> countCat = {};
      final Map<String, int> countMode = {};

      for (final row in rows) {
        totalExpense += row.amount;
        if (row.amount > highestSingle) highestSingle = row.amount;

        byCategory[row.category] = (byCategory[row.category] ?? 0) + row.amount;
        byMode[row.paymentMode] = (byMode[row.paymentMode] ?? 0) + row.amount;
        countCat[row.category] = (countCat[row.category] ?? 0) + 1;
        countMode[row.paymentMode] = (countMode[row.paymentMode] ?? 0) + 1;
      }

      // Daily average (days in range)
      final days = to.difference(from).inDays + 1;
      final dailyAvg = totalExpense / days.clamp(1, days);

      // Top category
      String topCatDb = '';
      double topCatAmt = 0.0;
      byCategory.forEach((k, v) {
        if (v > topCatAmt) {
          topCatAmt = v;
          topCatDb = k;
        }
      });
      final topLabel = topCatDb.isNotEmpty
          ? ExpenseCategory.fromDb(topCatDb).displayLabel
          : '—';

      // Category breakdown list
      final catBreakdown = byCategory.entries.map((e) {
        final cat = ExpenseCategory.fromDb(e.key);
        final pct = totalExpense > 0 ? (e.value / totalExpense) * 100 : 0.0;
        return ExpenseCategoryBreakdown(
          categoryDbValue: e.key,
          label: cat.displayLabel,
          amount: e.value,
          amountFormatted: _f(e.value),
          percentage: pct,
          count: countCat[e.key] ?? 0,
        );
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      // Payment mode breakdown list
      final modeBreakdown = byMode.entries.map((e) {
        final mode = PaymentMode.fromDb(e.key);
        return ExpensePaymentBreakdown(
          paymentModeLabel: mode.displayLabel,
          amount: e.value,
          amountFormatted: _f(e.value),
          count: countMode[e.key] ?? 0,
        );
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      return ExpenseSummaryModel(
        totalExpense: totalExpense,
        totalExpenseFormatted: _f(totalExpense),
        dailyAverage: dailyAvg,
        dailyAverageFormatted: _f(dailyAvg),
        totalCount: rows.length,
        highestSingleExpense: highestSingle,
        highestSingleFormatted: _f(highestSingle),
        topCategoryLabel: topLabel,
        topCategoryAmount: topCatAmt,
        topCategoryFormatted: _f(topCatAmt),
        categoryBreakdown: catBreakdown,
        paymentBreakdown: modeBreakdown,
      );
    } catch (e) {
      AppLogger.debug('❌ ExpenseRepository.computeSummary: $e');
      return ExpenseSummaryModel.zero();
    }
  }

  // ==========================================================================
  // 4. SAVE EXPENSE — Inserts into CashTransactions as EXPENSE type
  // ==========================================================================

  Future<bool> saveExpense({
    required ExpenseCategory category,
    required double amount,
    required PaymentMode paymentMode,
    required DateTime expenseDate,
    String? customLabel,
    String? description,
    String? partyName,
  }) async {
    try {
      final expenseId = await _generateExpenseId();

      await _db.into(_db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              txnId: expenseId,
              txnDate: expenseDate,
              type: CashTransactionType.expense.dbValue,
              category: category.dbValue,
              amount: Value(amount),
              paymentMode: Value(paymentMode.dbValue),
              customLabel: Value(customLabel),
              description: Value(description),
              partyName: Value(partyName),
              referenceType: const Value('MANUAL'),
              isAutoGenerated: const Value(false),
              isVoided: const Value(false),
            ),
          );
      return true;
    } catch (e) {
      AppLogger.debug('❌ ExpenseRepository.saveExpense: $e');
      return false;
    }
  }

  // ==========================================================================
  // 5. VOID EXPENSE — Soft delete (never hard-delete financial records)
  // ==========================================================================

  Future<bool> voidExpense(int id, String reason) async {
    try {
      await (_db.update(_db.cashTransactions)..where((t) => t.id.equals(id)))
          .write(CashTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: Value(reason),
        updatedAt: Value(DateTime.now()),
      ));
      return true;
    } catch (e) {
      AppLogger.debug('❌ ExpenseRepository.voidExpense: $e');
      return false;
    }
  }

  // ==========================================================================
  // 6. WATCH TODAY'S TOTAL — For dashboard integration
  // ==========================================================================

  Stream<double> watchTodayTotal() {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (_db.select(_db.cashTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.type.equals(CashTransactionType.expense.dbValue))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(dayStart))
          ..where((t) => t.txnDate.isSmallerOrEqualValue(dayEnd)))
        .watch()
        .map((rows) => rows.fold(0.0, (sum, r) => sum + r.amount));
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  Future<String> _generateExpenseId() async {
    final count = await (_db.select(_db.cashTransactions)
          ..where((t) => t.type.equals(CashTransactionType.expense.dbValue)))
        .get()
        .then((rows) => rows.length);
    final year = DateTime.now().year;
    return 'EXP-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  ExpenseModel _rowToModel(CashTransaction row) {
    final cat = ExpenseCategory.fromDb(row.category);

    // Resolve display label — for OTHER_EXPENSE uses customLabel
    final categoryLabel = (cat == ExpenseCategory.otherExpense &&
            row.customLabel != null &&
            row.customLabel!.isNotEmpty)
        ? row.customLabel!
        : cat.displayLabel;

    return ExpenseModel(
      id: row.id,
      expenseId: row.txnId,
      expenseDate: row.txnDate,
      category: cat,
      categoryLabel: categoryLabel,
      amount: row.amount,
      amountFormatted: _f(row.amount),
      paymentMode: PaymentMode.fromDb(row.paymentMode),
      customLabel: row.customLabel,
      description: row.description,
      partyName: row.partyName,
      referenceId: row.referenceId,
      isVoided: row.isVoided,
      isAutoGenerated: row.isAutoGenerated,
    );
  }
}