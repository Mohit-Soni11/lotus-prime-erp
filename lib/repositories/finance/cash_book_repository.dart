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
import '../../models/finance/cash_book/cash_book_enums.dart';
import '../../models/finance/cash_book/cash_transaction_model.dart';
import '../../models/finance/cash_book/cash_book_summary_model.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class CashBookRepository {
  final AppDatabase _db;
  CashBookRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

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
              m.txnId.toLowerCase().contains(q);
        }).toList();
      }

      return models;
    } catch (e) {
      AppLogger.debug('❌ CashBookRepository.fetchTransactions: $e');
      return [];
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
          ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
          ..where((t) => t.txnDate.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.txnDate)]))
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
      final rows = await (_db.select(_db.cashTransactions)
            ..where((t) => t.isVoided.equals(false))
            ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
            ..where((t) => t.txnDate.isSmallerOrEqualValue(to)))
          .get();

      double openingBalance = 0.0;
      try {
        final shop =
            await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
        openingBalance = shop?.openingCashBalance ?? 0.0;
      } catch (_) {}

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      int incomeCount = 0;
      int expenseCount = 0;

      final Map<String, double> incomeByCategory = {};
      final Map<String, double> expenseByCategory = {};

      for (final row in rows) {
        if (row.type == CashTransactionType.income.dbValue) {
          totalIncome += row.amount;
          incomeCount++;
          incomeByCategory[row.category] =
              (incomeByCategory[row.category] ?? 0) + row.amount;
        } else {
          totalExpense += row.amount;
          expenseCount++;
          expenseByCategory[row.category] =
              (expenseByCategory[row.category] ?? 0) + row.amount;
        }
      }

      final closingBalance = openingBalance + totalIncome - totalExpense;
      final netFlow = totalIncome - totalExpense;

      final incomeBreakdown = _buildBreakdown(
          incomeByCategory, CashTransactionType.income, totalIncome, rows);
      final expenseBreakdown = _buildBreakdown(
          expenseByCategory, CashTransactionType.expense, totalExpense, rows);

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
        totalTransactions: rows.length,
        incomeCount: incomeCount,
        expenseCount: expenseCount,
      );
    } catch (e) {
      AppLogger.debug('❌ CashBookRepository.computeSummary: $e');
      return CashBookSummaryModel.zero();
    }
  }

  // ==========================================================================
  // 5. SYNC AUTO-ENTRIES FROM BILLS (POS → Income)
  // ==========================================================================

  Future<void> syncBillsToIncome(DateTime date) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final bills = await (_db.select(_db.bills)
            ..where((t) => t.billDate.isBiggerOrEqualValue(dayStart))
            ..where((t) => t.billDate.isSmallerOrEqualValue(dayEnd))
            ..where((t) => t.status.equals('ACTIVE')))
          .get();

      for (final bill in bills) {
        final existing = await (_db.select(_db.cashTransactions)
              ..where((t) => t.referenceId.like('${bill.billNo}%'))
              ..where((t) => t.referenceType.equals('BILL')))
            .get();

        if (existing.isNotEmpty) continue;
        if (bill.paidAmount <= 0) continue;

        final txnId = await _generateTxnId();

        await _db.into(_db.cashTransactions).insert(
              CashTransactionsCompanion.insert(
                txnId: txnId,
                txnDate: bill.billDate,
                type: CashTransactionType.income.dbValue,
                category: IncomeCategory.sale.dbValue,
                amount: Value(bill.paidAmount),
                paymentMode: Value(PaymentMode.cash.dbValue),
                description: Value('Sale — ${bill.billNo}'),
                referenceId: Value(bill.billNo),
                referenceType: const Value('BILL'),
                partyName: Value(bill.customerName),
                isAutoGenerated: const Value(true),
                isVoided: const Value(false),
              ),
            );
      }
    } catch (e) {
      AppLogger.debug('❌ CashBookRepository.syncBillsToIncome: $e');
    }
  }

  // ==========================================================================
  // 6. SAVE MANUAL TRANSACTION — with customLabel support
  // ==========================================================================

  Future<bool> saveTransaction({
    required CashTransactionType type,
    required String categoryDbValue,
    required double amount,
    required PaymentMode paymentMode,
    required DateTime txnDate,
    String? customLabel,
    String? description,
    String? partyName,
  }) async {
    try {
      final txnId = await _generateTxnId();

      await _db.into(_db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              txnId: txnId,
              txnDate: txnDate,
              type: type.dbValue,
              category: categoryDbValue,
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
      AppLogger.debug('❌ CashBookRepository.saveTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 7. VOID TRANSACTION (Soft Delete)
  // ==========================================================================

  Future<bool> voidTransaction(int id, String reason) async {
    try {
      await (_db.update(_db.cashTransactions)..where((t) => t.id.equals(id)))
          .write(CashTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: Value(reason),
      ));
      return true;
    } catch (e) {
      AppLogger.debug('❌ CashBookRepository.voidTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 8. UPDATE OPENING BALANCE
  // ==========================================================================

  Future<bool> updateOpeningBalance(double amount) async {
    try {
      final shop =
          await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
      if (shop == null) return false;

      await (_db.update(_db.shopProfiles)..where((t) => t.id.equals(shop.id)))
          .write(ShopProfilesCompanion(
        openingCashBalance: Value(amount),
      ));
      return true;
    } catch (e) {
      AppLogger.debug('❌ CashBookRepository.updateOpeningBalance: $e');
      return false;
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  Future<String> _generateTxnId() async {
    final count = await _db.cashTransactions.count().getSingle();
    final year = DateTime.now().year;
    return 'TXN-$year-${(count + 1).toString().padLeft(4, '0')}';
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
    List<CashTransaction> allRows,
  ) {
    final items = map.entries.map((e) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;

      // For OTHER_* find most common customLabel to show in breakdown
      String label;
      if (type == CashTransactionType.income &&
          e.key == IncomeCategory.otherIncome.dbValue) {
        final customLabels = allRows
            .where((r) => r.category == e.key && r.customLabel != null)
            .map((r) => r.customLabel!)
            .toList();
        label = customLabels.isNotEmpty
            ? 'Other (${customLabels.length})'
            : 'Other';
      } else if (type == CashTransactionType.expense &&
          e.key == ExpenseCategory.otherExpense.dbValue) {
        final customLabels = allRows
            .where((r) => r.category == e.key && r.customLabel != null)
            .map((r) => r.customLabel!)
            .toList();
        label = customLabels.isNotEmpty
            ? 'Other (${customLabels.length})'
            : 'Other';
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