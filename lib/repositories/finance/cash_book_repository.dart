// =============================================================================
// FILE        : cash_book_repository.dart
// MODULE      : Accounts / Cash Book
// LAYER       : Repository / Data Access
// DESCRIPTION : All DB read/write operations for Cash Book module.
//               v2 — customLabel support + fetchDashboardSummary() for
//               Cash Register card live connection.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/transactions/domain/services/finance_transaction_numbering.dart';
import '../../models/finance/cash_book/cash_book_enums.dart';
import '../../models/finance/cash_book/cash_transaction_model.dart';
import '../../models/finance/cash_book/cash_book_summary_model.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class CashBookRepository {
  final AppDatabase _db;
  CashBookRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  FinanceTransactionNumbering get _numbering =>
      FinanceTransactionNumbering(_db);

  // ── Formatter ─────────────────────────────────────────────────────────────
  static final _currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  static String _fmt(double v) => _currencyFmt.format(v);

  // ==========================================================================
  // 1. FETCH TRANSACTIONS — Filtered by date range
  // ==========================================================================

  Future<List<CashTransactionModel>> fetchTransactions({
    required DateTime from,
    required DateTime to,
    CashBookFilter filter = CashBookFilter.all,
    String? searchQuery,
  }) async {
    try {
      var query = _db.select(_db.cashTransactions)
        ..where((t) => t.isVoided.equals(false))
        ..where((t) => t.paymentMode.equals(PaymentMode.cash.dbValue))
        ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
        ..where((t) => t.txnDate.isSmallerOrEqualValue(to));

      if (filter == CashBookFilter.incomeOnly) {
        query = query
          ..where((t) => t.type.equals(CashTransactionType.income.dbValue));
      } else if (filter == CashBookFilter.expenseOnly) {
        query = query
          ..where((t) => t.type.equals(CashTransactionType.expense.dbValue));
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
              (m.referenceId?.toLowerCase().contains(q) ?? false) ||
              m.amount.toStringAsFixed(2).contains(q) ||
              m.txnId.toLowerCase().contains(q);
        }).toList();
      }

      return models;
    } catch (e, stackTrace) {
      AppLogger.error('Cash Book transactions could not be loaded.',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==========================================================================
  // 2. WATCH TRANSACTIONS — Live stream (real-time UI updates)
  // ==========================================================================

  Stream<List<CashTransactionModel>> watchTransactions({
    required DateTime from,
    required DateTime to,
  }) {
    return (_db.select(_db.cashTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.paymentMode.equals(PaymentMode.cash.dbValue))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
          ..where((t) => t.txnDate.isSmallerOrEqualValue(to))
          ..orderBy([
            (t) => OrderingTerm.desc(t.txnDate),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  // ==========================================================================
  // 3. WATCH EXPENSE TOTAL — For Cash Register dashboard card
  //    Returns a live stream of today's total expenses from CashTransactions.
  //    Cash Register uses this to show real Paid Out figure.
  // ==========================================================================

  Stream<double> watchTodayExpenseTotal() {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (_db.select(_db.cashTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.type.equals(CashTransactionType.expense.dbValue))
          ..where((t) => t.paymentMode.equals(PaymentMode.cash.dbValue))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(dayStart))
          ..where((t) => t.txnDate.isSmallerOrEqualValue(dayEnd)))
        .watch()
        .map((rows) => rows.fold(0.0, (sum, r) => sum + r.amount));
  }

  // ==========================================================================
  // 4. COMPUTE SUMMARY — Aggregated totals for selected range
  // ==========================================================================

  Future<CashBookSummaryModel> computeSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows = await _db.customSelect(
        '''SELECT type, category, SUM(amount) AS total, COUNT(*) AS entry_count,
                  SUM(CASE WHEN custom_label IS NOT NULL THEN 1 ELSE 0 END)
                    AS custom_label_count
           FROM cash_transactions
           WHERE is_voided = 0 AND payment_mode = 'CASH'
             AND txn_date >= ? AND txn_date <= ?
           GROUP BY type, category''',
        variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
        readsFrom: {_db.cashTransactions},
      ).get();

      final prior = await _db.customSelect(
        '''SELECT COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount
            WHEN type = 'EXPENSE' THEN -amount ELSE 0 END), 0) AS movement
           FROM cash_transactions
           WHERE is_voided = 0 AND payment_mode = 'CASH' AND txn_date < ?''',
        variables: [Variable.withDateTime(from)],
        readsFrom: {_db.cashTransactions},
      ).getSingle();

      final shop =
          await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
      final openingBalance =
          (shop?.openingCashBalance ?? 0.0) + prior.read<double>('movement');

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      int incomeCount = 0;
      int expenseCount = 0;

      final Map<String, double> incomeByCategory = {};
      final Map<String, double> expenseByCategory = {};
      final Map<String, int> customLabelCounts = {};

      for (final row in rows) {
        final type = row.read<String>('type');
        final category = row.read<String>('category');
        final amount = row.read<double>('total');
        final count = row.read<int>('entry_count');
        customLabelCounts[category] = row.read<int>('custom_label_count');
        if (type == CashTransactionType.income.dbValue) {
          totalIncome += amount;
          incomeCount += count;
          incomeByCategory[category] = amount;
        } else if (type == CashTransactionType.expense.dbValue) {
          totalExpense += amount;
          expenseCount += count;
          expenseByCategory[category] = amount;
        }
      }

      final closingBalance = openingBalance + totalIncome - totalExpense;
      final netFlow = totalIncome - totalExpense;

      final incomeBreakdown = _buildBreakdown(incomeByCategory,
          CashTransactionType.income, totalIncome, customLabelCounts);
      final expenseBreakdown = _buildBreakdown(expenseByCategory,
          CashTransactionType.expense, totalExpense, customLabelCounts);

      return CashBookSummaryModel(
        openingBalance: openingBalance,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        closingBalance: closingBalance,
        netFlow: netFlow,
        openingBalanceStr: _fmt(openingBalance),
        totalIncomeStr: _fmt(totalIncome),
        totalExpenseStr: _fmt(totalExpense),
        closingBalanceStr: _fmt(closingBalance),
        netFlowStr: _fmt(netFlow.abs()),
        incomeBreakdown: incomeBreakdown,
        expenseBreakdown: expenseBreakdown,
        totalTransactions: incomeCount + expenseCount,
        incomeCount: incomeCount,
        expenseCount: expenseCount,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Cash Book summary could not be calculated.',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==========================================================================
  // 5. SYNC AUTO-ENTRIES FROM BILLS (POS → Income)
  // ==========================================================================

  Future<int> syncBillsToIncome(DateTime date) async {
    try {
      return await _db.transaction(() async {
        var created = 0;
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final bills = await (_db.select(_db.bills)
              ..where((t) => t.billDate.isBiggerOrEqualValue(dayStart))
              ..where((t) => t.billDate.isSmallerOrEqualValue(dayEnd))
              ..where((t) => t.status.equals('ACTIVE')))
            .get();

        for (final bill in bills) {
          final legacy = await (_db.select(_db.cashTransactions)
                ..where((t) =>
                    t.referenceId.equals(bill.billNo) &
                    t.referenceType.equals('BILL') &
                    t.category.equals(IncomeCategory.sale.dbValue) &
                    t.paymentMode.equals(PaymentMode.cash.dbValue) &
                    t.isAutoGenerated.equals(true) &
                    t.isVoided.equals(false)))
              .get();
          for (final row in legacy) {
            if ((row.amount - bill.cashPaid).abs() < 0.005) continue;
            await (_db.update(_db.cashTransactions)
                  ..where((t) => t.id.equals(row.id)))
                .write(CashTransactionsCompanion(
              isVoided: const Value(true),
              voidReason: const Value('Corrected legacy bill cash sync'),
              updatedAt: Value(DateTime.now()),
            ));
          }
          final existing = await (_db.select(_db.cashTransactions)
                ..where((t) =>
                    t.referenceId.equals(bill.billNo) |
                    t.referenceId.equals('${bill.billNo}#CASH'))
                ..where((t) => t.referenceType.equals('BILL'))
                ..where((t) => t.paymentMode.equals(PaymentMode.cash.dbValue)))
              .get();

          if (existing.any((row) => !row.isVoided)) continue;
          if (existing.isNotEmpty &&
              existing.every((row) => row.referenceId != bill.billNo)) {
            continue;
          }
          if (bill.cashPaid <= 0) continue;

          final txnId = await _generateTxnId();

          await _db.into(_db.cashTransactions).insert(
                CashTransactionsCompanion.insert(
                  txnId: txnId,
                  txnDate: bill.billDate,
                  type: CashTransactionType.income.dbValue,
                  category: IncomeCategory.sale.dbValue,
                  amount: Value(bill.cashPaid),
                  paymentMode: Value(PaymentMode.cash.dbValue),
                  description: Value('Sale — ${bill.billNo}'),
                  referenceId: Value(bill.billNo),
                  referenceType: const Value('BILL'),
                  partyName: Value(bill.customerName),
                  isAutoGenerated: const Value(true),
                  isVoided: const Value(false),
                ),
              );
          created++;
        }
        return created;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Cash receipt reconciliation failed.',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==========================================================================
  // 6. SAVE MANUAL TRANSACTION — with customLabel support
  // ==========================================================================

  Future<bool> saveExtraCashIncome({
    required String categoryDbValue,
    required double amount,
    required DateTime txnDate,
    String? customLabel,
    String? description,
    String? partyName,
  }) async {
    if (description == null || description.trim().isEmpty) return false;
    if (categoryDbValue != IncomeCategory.miscIncome.dbValue &&
        categoryDbValue != IncomeCategory.otherIncome.dbValue) {
      return false;
    }
    if (categoryDbValue == IncomeCategory.otherIncome.dbValue &&
        (customLabel == null || customLabel.trim().isEmpty)) {
      return false;
    }
    if (!amount.isFinite ||
        amount <= 0 ||
        (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
      return false;
    }
    try {
      await _db.transaction(() async {
        final txnId = await _generateTxnId();
        await _db.into(_db.cashTransactions).insert(
              CashTransactionsCompanion.insert(
                txnId: txnId,
                txnDate: txnDate,
                type: CashTransactionType.income.dbValue,
                category: categoryDbValue,
                amount: Value(amount),
                paymentMode: Value(PaymentMode.cash.dbValue),
                customLabel: Value(customLabel),
                description: Value(description),
                partyName: Value(partyName),
                referenceType: const Value('MANUAL'),
                isAutoGenerated: const Value(false),
                isVoided: const Value(false),
              ),
            );
      });
      return true;
    } catch (e) {
      AppLogger.debug('CashBookRepository.saveExtraCashIncome: $e');
      return false;
    }
  }

  // ==========================================================================
  // 7. VOID TRANSACTION (Soft Delete)
  // ==========================================================================

  Future<bool> voidTransaction(int id, String reason) async {
    if (reason.trim().isEmpty) return false;
    try {
      final row = await (_db.select(_db.cashTransactions)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null ||
          row.isAutoGenerated ||
          row.isVoided ||
          row.paymentMode != PaymentMode.cash.dbValue) {
        return false;
      }
      final changed = await (_db.update(_db.cashTransactions)
            ..where((t) =>
                t.id.equals(id) &
                t.isAutoGenerated.equals(false) &
                t.isVoided.equals(false) &
                t.paymentMode.equals(PaymentMode.cash.dbValue)))
          .write(CashTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: Value(reason.trim()),
        updatedAt: Value(DateTime.now()),
      ));
      return changed == 1;
    } catch (e) {
      AppLogger.debug('❌ CashBookRepository.voidTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 8. UPDATE OPENING BALANCE
  // ==========================================================================

  Future<({bool canSet, double amount})> fetchInitialCashSetup() async {
    final shop =
        await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
    return (
      canSet: shop != null && !await _hasFinancialActivity(),
      amount: shop?.openingCashBalance ?? 0,
    );
  }

  Future<bool> updateOpeningBalance(double amount) async {
    if (!amount.isFinite || amount < 0) return false;
    try {
      return await _db.transaction(() async {
        if (await _hasFinancialActivity()) return false;
        final shop =
            await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
        if (shop == null) return false;
        final changed = await (_db.update(_db.shopProfiles)
              ..where((t) => t.id.equals(shop.id)))
            .write(ShopProfilesCompanion(
          openingCashBalance: Value(amount),
        ));
        return changed == 1;
      });
    } catch (e) {
      AppLogger.debug('❌ CashBookRepository.updateOpeningBalance: $e');
      return false;
    }
  }

  Future<bool> _hasFinancialActivity() async {
    if (await _db.cashTransactions.count().getSingle() > 0 ||
        await _db.bankTransactions.count().getSingle() > 0) {
      return true;
    }
    final closureTable = await _db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'finance_day_closures'",
        )
        .getSingleOrNull();
    if (closureTable == null) return false;
    final closure = await _db
        .customSelect(
          'SELECT 1 FROM finance_day_closures LIMIT 1',
        )
        .getSingleOrNull();
    return closure != null;
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  Future<String> _generateTxnId() async {
    return _numbering.nextCashTransactionId();
  }

  CashTransactionModel _rowToModel(CashTransaction row) {
    final type = CashTransactionType.fromDb(row.type);

    // Resolve category label — handles 'Other' custom labels
    final categoryLabel = resolveDisplayLabel(
      type: type,
      categoryDbValue: row.category,
      customLabel: row.customLabel,
    );

    return CashTransactionModel(
      id: row.id,
      txnId: row.txnId,
      txnDate: row.txnDate,
      type: type,
      categoryDbValue: row.category,
      categoryLabel: categoryLabel,
      amount: row.amount,
      amountFormatted: _fmt(row.amount),
      paymentMode: PaymentMode.fromDb(row.paymentMode),
      customLabel: row.customLabel,
      description: row.description,
      referenceId: row.referenceId,
      referenceType: row.referenceType,
      partyName: row.partyName,
      isAutoGenerated: row.isAutoGenerated,
      isVoided: row.isVoided,
    );
  }

  List<CategoryBreakdownItem> _buildBreakdown(
    Map<String, double> map,
    CashTransactionType type,
    double total,
    Map<String, int> customLabelCounts,
  ) {
    final items = map.entries.map((e) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;

      // For OTHER_* find most common customLabel to show in breakdown
      String label;
      if (type == CashTransactionType.income &&
          e.key == IncomeCategory.otherIncome.dbValue) {
        final count = customLabelCounts[e.key] ?? 0;
        label = count > 0 ? 'Other ($count)' : 'Other';
      } else if (type == CashTransactionType.expense &&
          e.key == ExpenseCategory.otherExpense.dbValue) {
        final count = customLabelCounts[e.key] ?? 0;
        label = count > 0 ? 'Other ($count)' : 'Other';
      } else {
        label = resolveDisplayLabel(
          type: type,
          categoryDbValue: e.key,
        );
      }

      return CategoryBreakdownItem(
        label: label,
        categoryDbValue: e.key,
        type: type,
        amount: e.value,
        amountFormatted: _fmt(e.value),
        percentage: pct,
      );
    }).toList();

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }
}
