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
import 'package:lotus_erp/features/finance/transactions/domain/services/finance_transaction_numbering.dart';
import '../../models/finance/bank_book/bank_book_enums.dart' as bank;
import '../../models/finance/cash_book/cash_book_enums.dart';
import '../../models/finance/expense/expense_model.dart';
import '../../models/finance/expense/expense_summary_model.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class ExpenseBankAccountOption {
  const ExpenseBankAccountOption(this.id, this.name);

  final int id;
  final String name;
}

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

  Future<List<ExpenseBankAccountOption>> listActiveBankAccounts() async {
    final accounts = await (_db.select(_db.bankAccounts)
          ..where((account) => account.isActive.equals(true)))
        .get();
    accounts.sort((a, b) => b.isPrimary == a.isPrimary
        ? a.accountName.compareTo(b.accountName)
        : b.isPrimary
            ? 1
            : -1);
    return accounts
        .map((account) => ExpenseBankAccountOption(
              account.id,
              '${account.accountName} • ${account.bankName}',
            ))
        .toList(growable: false);
  }

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
    int? bankAccountId,
    required DateTime expenseDate,
    String? customLabel,
    String? description,
    String? partyName,
  }) async {
    if (!amount.isFinite ||
        amount <= 0 ||
        (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
      return false;
    }
    try {
      await _db.transaction(() async {
        final account = paymentMode == PaymentMode.cash
            ? null
            : await (_db.select(_db.bankAccounts)
                  ..where((row) =>
                      row.id.equals(bankAccountId ?? -1) &
                      row.isActive.equals(true)))
                .getSingleOrNull();
        if (paymentMode != PaymentMode.cash && account == null) {
          throw StateError('Select an active bank account for this expense.');
        }
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
                referenceId: paymentMode == PaymentMode.cash
                    ? const Value.absent()
                    : Value(expenseId),
                referenceType: Value(
                    paymentMode == PaymentMode.cash ? 'MANUAL' : 'EXPENSE'),
                isAutoGenerated: const Value(false),
                isVoided: const Value(false),
              ),
            );
        if (account != null) {
          final bankId =
              await FinanceTransactionNumbering(_db).nextBankTransactionId();
          await _db.into(_db.bankTransactions).insert(
                BankTransactionsCompanion.insert(
                  txnId: bankId,
                  accountId: Value(account.id),
                  txnDate: expenseDate,
                  type: bank.BankTransactionType.debit.dbValue,
                  category: _bankCategory(category).dbValue,
                  amount: Value(amount),
                  paymentMode: Value(_bankMode(paymentMode).dbValue),
                  description: Value(description),
                  partyName: Value(partyName),
                  referenceId: Value(expenseId),
                  referenceType: const Value('EXPENSE'),
                  isAutoGenerated: const Value(true),
                ),
              );
        }
      });
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
    if (reason.trim().isEmpty) return false;
    try {
      return await _db.transaction(() async {
        final expense = await (_db.select(_db.cashTransactions)
              ..where((row) => row.id.equals(id)))
            .getSingleOrNull();
        if (expense == null || expense.isVoided || expense.isAutoGenerated) {
          return false;
        }
        final now = DateTime.now();
        await (_db.update(_db.cashTransactions)
              ..where((row) => row.id.equals(id)))
            .write(CashTransactionsCompanion(
          isVoided: const Value(true),
          voidReason: Value(reason.trim()),
          updatedAt: Value(now),
        ));
        if (expense.referenceType == 'EXPENSE' && expense.referenceId != null) {
          await (_db.update(_db.bankTransactions)
                ..where((row) =>
                    row.referenceType.equals('EXPENSE') &
                    row.referenceId.equals(expense.referenceId!)))
              .write(BankTransactionsCompanion(
            isVoided: const Value(true),
            voidReason: Value(reason.trim()),
            updatedAt: Value(now),
          ));
        }
        return true;
      });
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
    return FinanceTransactionNumbering(_db).nextExpenseTransactionId();
  }

  static bank.BankPaymentMode _bankMode(PaymentMode mode) => switch (mode) {
        PaymentMode.upi => bank.BankPaymentMode.upi,
        PaymentMode.card => bank.BankPaymentMode.card,
        PaymentMode.bank => bank.BankPaymentMode.neft,
        PaymentMode.cheque => bank.BankPaymentMode.cheque,
        PaymentMode.cash => throw ArgumentError('Cash does not use Bank Book'),
      };

  static bank.BankDebitCategory _bankCategory(ExpenseCategory category) =>
      switch (category) {
        ExpenseCategory.shopRent => bank.BankDebitCategory.shopRent,
        ExpenseCategory.staffSalary => bank.BankDebitCategory.staffSalary,
        ExpenseCategory.electricity => bank.BankDebitCategory.electricity,
        ExpenseCategory.purchasePayment =>
          bank.BankDebitCategory.purchasePayment,
        ExpenseCategory.maintenance => bank.BankDebitCategory.maintenance,
        ExpenseCategory.advertising => bank.BankDebitCategory.advertising,
        ExpenseCategory.transport => bank.BankDebitCategory.transport,
        ExpenseCategory.bankCharges => bank.BankDebitCategory.bankCharges,
        ExpenseCategory.girviGiven => bank.BankDebitCategory.girviGiven,
        ExpenseCategory.governmentFees => bank.BankDebitCategory.gstPayment,
        ExpenseCategory.ownerDrawing ||
        ExpenseCategory.personalHousehold ||
        ExpenseCategory.personalFamily ||
        ExpenseCategory.personalMedical ||
        ExpenseCategory.personalEducation ||
        ExpenseCategory.personalTravel =>
          bank.BankDebitCategory.ownerDrawing,
        ExpenseCategory.miscExpense ||
        ExpenseCategory.otherExpense =>
          bank.BankDebitCategory.miscDebit,
      };

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
