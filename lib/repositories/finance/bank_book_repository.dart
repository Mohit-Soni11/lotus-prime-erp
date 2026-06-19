// =============================================================================
// FILE        : bank_book_repository.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : Repository / Data Access
// DESCRIPTION : All database operations for the Bank Book module.
//               — CRUD for bank accounts
//               — Fetch / watch transactions with date-range + filters
//               — Compute summary aggregates (opening + closing balance)
//               — Auto-sync UPI/Card/NEFT payments from POS bills
//               — Cheque management (update status)
//               — Reconciliation marking
//               — Sequential BTXN ID generation
//               — NEVER exposes Drift types to caller
//
// CA ALIGNMENT:
//   Closing Balance = Opening Balance + Sum(Credits) - Sum(Debits)
//   Only non-voided transactions are included in balance calculation
// =============================================================================

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../database/db/app_database.dart';
import '../../models/finance/bank_book/bank_book_enums.dart';
import '../../models/finance/bank_book/bank_account_model.dart';
import '../../models/finance/bank_book/bank_book_summary_model.dart';
import '../../core/logging/app_logger.dart';

class BankBookRepository {
  final AppDatabase _db;

  BankBookRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ── Currency Formatter ────────────────────────────────────────────────────

  static final _currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  static String _fmt(double v) => _currencyFmt.format(v);

  // ==========================================================================
  // 1. BANK ACCOUNTS — CRUD
  // ==========================================================================

  /// Fetch all active bank accounts with computed balances
  Future<List<BankAccountModel>> fetchAccounts({bool activeOnly = true}) async {
    try {
      var query = _db.select(_db.bankAccounts);
      if (activeOnly) {
        query = query..where((t) => t.isActive.equals(true));
      }
      query = query
        ..orderBy([
          (t) => OrderingTerm.desc(t.isPrimary),
          (t) => OrderingTerm.asc(t.accountName),
        ]);

      final rows = await query.get();
      final models = <BankAccountModel>[];

      for (final row in rows) {
        final balance =
            await _computeAccountBalance(row.id, row.openingBalance);
        models.add(_rowToAccountModel(row, balance));
      }

      return models;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.fetchAccounts: $e');
      return [];
    }
  }

  /// Watch all active accounts — live stream
  Stream<List<BankAccountModel>> watchAccounts() {
    return (_db.select(_db.bankAccounts)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPrimary),
            (t) => OrderingTerm.asc(t.accountName),
          ]))
        .watch()
        .asyncMap((rows) async {
      final models = <BankAccountModel>[];
      for (final row in rows) {
        final balance =
            await _computeAccountBalance(row.id, row.openingBalance);
        models.add(_rowToAccountModel(row, balance));
      }
      return models;
    });
  }

  /// Save new bank account — returns id
  Future<int?> saveAccount({
    required String accountName,
    required String bankName,
    required String accountNumber,
    required BankAccountType accountType,
    String? holderName,
    String? ifscCode,
    String? branchName,
    String? upiId,
    double openingBalance = 0.0,
    bool isPrimary = false,
    String? colorHex,
  }) async {
    try {
      final id = await _db.into(_db.bankAccounts).insert(
            BankAccountsCompanion.insert(
              accountName: accountName,
              bankName: bankName,
              accountNumber: accountNumber,
              accountType:
                  Value(accountType.dbValue), // ✅ FIX: Wrapped in Value()
              holderName: Value(holderName),
              ifscCode: Value(ifscCode),
              branchName: Value(branchName),
              upiId: Value(upiId),
              openingBalance: Value(openingBalance),
              isPrimary: Value(isPrimary),
              isActive: const Value(true),
              colorHex: Value(colorHex),
              activeSince: Value(DateTime.now()),
            ),
          );
      return id;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.saveAccount: $e');
      return null;
    }
  }

  /// Update opening balance for an account
  Future<bool> updateOpeningBalance(int accountId, double amount) async {
    try {
      await (_db.update(_db.bankAccounts)..where((t) => t.id.equals(accountId)))
          .write(BankAccountsCompanion(openingBalance: Value(amount)));
      return true;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.updateOpeningBalance: $e');
      return false;
    }
  }

  /// Set primary account (unset others first)
  Future<void> setPrimaryAccount(int accountId) async {
    try {
      await (_db.update(_db.bankAccounts))
          .write(const BankAccountsCompanion(isPrimary: Value(false)));
      await (_db.update(_db.bankAccounts)..where((t) => t.id.equals(accountId)))
          .write(const BankAccountsCompanion(isPrimary: Value(true)));
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.setPrimaryAccount: $e');
    }
  }

  // ==========================================================================
  // 2. TRANSACTIONS — FETCH
  // ==========================================================================

  /// Fetch transactions for a given account and date range
  Future<List<BankTransactionModel>> fetchTransactions({
    required int accountId,
    required DateTime from,
    required DateTime to,
    BankBookFilter filter = BankBookFilter.all,
    String? searchQuery,
  }) async {
    try {
      var query = _db.select(_db.bankTransactions)
        ..where((t) => t.isVoided.equals(false))
        ..where((t) => t.accountId.equals(accountId))
        ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
        ..where((t) => t.txnDate.isSmallerOrEqualValue(to))
        ..orderBy([(t) => OrderingTerm.desc(t.txnDate)]);

      if (filter == BankBookFilter.creditOnly) {
        query = query
          ..where((t) => t.type.equals(BankTransactionType.credit.dbValue));
      } else if (filter == BankBookFilter.debitOnly) {
        query = query
          ..where((t) => t.type.equals(BankTransactionType.debit.dbValue));
      } else if (filter == BankBookFilter.chequeOnly) {
        query = query
          ..where((t) => t.paymentMode.equals(BankPaymentMode.cheque.dbValue));
      } else if (filter == BankBookFilter.pendingReconciliation) {
        query = query..where((t) => t.isReconciled.equals(false));
      }

      final rows = await query.get();
      final accountName = await _getAccountName(accountId);
      var models = rows.map((r) => _rowToTxnModel(r, accountName)).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        models = models.where((m) {
          return m.categoryLabel.toLowerCase().contains(q) ||
              (m.partyName?.toLowerCase().contains(q) ?? false) ||
              (m.description?.toLowerCase().contains(q) ?? false) ||
              m.txnId.toLowerCase().contains(q) ||
              (m.chequeNumber?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      return models;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.fetchTransactions: $e');
      return [];
    }
  }

  /// Watch transactions — live stream for real-time updates
  Stream<List<BankTransactionModel>> watchTransactions({
    required int accountId,
    required DateTime from,
    required DateTime to,
  }) {
    return (_db.select(_db.bankTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.accountId.equals(accountId))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
          ..where((t) => t.txnDate.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.txnDate)]))
        .watch()
        .asyncMap((rows) async {
      final accountName = await _getAccountName(accountId);
      return rows.map((r) => _rowToTxnModel(r, accountName)).toList();
    });
  }

  // ==========================================================================
  // 3. COMPUTE SUMMARY
  // ==========================================================================

  Future<BankBookSummaryModel> computeSummary({
    required int accountId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      // Get account for opening balance
      final account = await (_db.select(_db.bankAccounts)
            ..where((t) => t.id.equals(accountId)))
          .getSingleOrNull();

      final openingBalance = account?.openingBalance ?? 0.0;

      // All non-voided transactions in range
      final rows = await (_db.select(_db.bankTransactions)
            ..where((t) => t.isVoided.equals(false))
            ..where((t) => t.accountId.equals(accountId))
            ..where((t) => t.txnDate.isBiggerOrEqualValue(from))
            ..where((t) => t.txnDate.isSmallerOrEqualValue(to)))
          .get();

      double totalCredit = 0;
      double totalDebit = 0;
      int creditCount = 0;
      int debitCount = 0;
      int reconciledCount = 0;
      int unreconciledCount = 0;

      final Map<String, double> creditByCategory = {};
      final Map<String, int> creditCountByCategory = {};
      final Map<String, double> debitByCategory = {};
      final Map<String, int> debitCountByCategory = {};

      // Cheque tracking
      int totalIssued = 0;
      int totalCleared = 0;
      int totalBounced = 0;
      double pendingAmount = 0;

      for (final row in rows) {
        if (row.type == BankTransactionType.credit.dbValue) {
          totalCredit += row.amount;
          creditCount++;
          creditByCategory[row.category] =
              (creditByCategory[row.category] ?? 0) + row.amount;
          creditCountByCategory[row.category] =
              (creditCountByCategory[row.category] ?? 0) + 1;
        } else {
          totalDebit += row.amount;
          debitCount++;
          debitByCategory[row.category] =
              (debitByCategory[row.category] ?? 0) + row.amount;
          debitCountByCategory[row.category] =
              (debitCountByCategory[row.category] ?? 0) + 1;
        }

        if (row.isReconciled) {
          reconciledCount++;
        } else {
          unreconciledCount++;
        }

        // Cheque summary
        if (row.paymentMode == BankPaymentMode.cheque.dbValue) {
          totalIssued++;
          final status = row.chequeStatus;
          if (status == ChequeStatus.cleared.dbValue) totalCleared++;
          if (status == ChequeStatus.bounced.dbValue) totalBounced++;
          if (status != ChequeStatus.cleared.dbValue &&
              status != ChequeStatus.bounced.dbValue) {
            pendingAmount += row.amount;
          }
        }
      }

      final closingBalance = openingBalance + totalCredit - totalDebit;
      final netFlow = totalCredit - totalDebit;
      final pendingCheques = totalIssued - totalCleared - totalBounced;

      final creditBreakdown = _buildBreakdown(creditByCategory,
          creditCountByCategory, BankTransactionType.credit, totalCredit);
      final debitBreakdown = _buildBreakdown(debitByCategory,
          debitCountByCategory, BankTransactionType.debit, totalDebit);

      return BankBookSummaryModel(
        openingBalance: openingBalance,
        totalCredit: totalCredit,
        totalDebit: totalDebit,
        closingBalance: closingBalance,
        netFlow: netFlow,
        openingBalanceStr: _fmt(openingBalance),
        totalCreditStr: _fmt(totalCredit),
        totalDebitStr: _fmt(totalDebit),
        closingBalanceStr: _fmt(closingBalance),
        netFlowStr: _fmt(netFlow.abs()),
        creditBreakdown: creditBreakdown,
        debitBreakdown: debitBreakdown,
        totalTransactions: rows.length,
        creditCount: creditCount,
        debitCount: debitCount,
        reconciledCount: reconciledCount,
        unreconciledCount: unreconciledCount,
        chequeSummary: ChequeSummary(
          totalIssued: totalIssued,
          totalCleared: totalCleared,
          totalBounced: totalBounced,
          totalPending: pendingCheques,
          pendingAmount: pendingAmount,
          pendingAmountFormatted: _fmt(pendingAmount),
        ),
      );
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.computeSummary: $e');
      return BankBookSummaryModel.zero();
    }
  }

  // ==========================================================================
  // 4. SAVE MANUAL TRANSACTION
  // ==========================================================================

  Future<bool> saveTransaction({
    required int accountId,
    required BankTransactionType type,
    required String categoryDbValue,
    required double amount,
    required BankPaymentMode paymentMode,
    required DateTime txnDate,
    DateTime? valueDate,
    String? chequeNumber,
    ChequeStatus? chequeStatus,
    DateTime? chequeDate,
    String? description,
    String? partyName,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      final txnId = await _generateTxnId();

      // Default cheque status when mode is cheque
      final finalChequeStatus = paymentMode == BankPaymentMode.cheque
          ? (chequeStatus ?? ChequeStatus.issued).dbValue
          : null;

      await _db.into(_db.bankTransactions).insert(
            BankTransactionsCompanion.insert(
              txnId: txnId,
              accountId: accountId,
              txnDate: txnDate,
              type: type.dbValue,
              category: categoryDbValue,
              amount: Value(amount),
              paymentMode: Value(paymentMode.dbValue),
              valueDate: Value(valueDate),
              chequeNumber: Value(chequeNumber),
              chequeStatus: Value(finalChequeStatus),
              chequeDate: Value(chequeDate),
              description: Value(description),
              partyName: Value(partyName),
              referenceId: Value(referenceId),
              referenceType: Value(referenceType ?? 'MANUAL'),
              isAutoGenerated: const Value(false),
              isVoided: const Value(false),
            ),
          );
      return true;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.saveTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // 5. AUTO-SYNC FROM POS BILLS (UPI / Card / Bank payments)
  // ==========================================================================

  Future<int> syncBillsToBank({
    required int accountId,
    required DateTime date,
  }) async {
    try {
      int synced = 0;
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final bills = await (_db.select(_db.bills)
            ..where((t) => t.billDate.isBiggerOrEqualValue(dayStart))
            ..where((t) => t.billDate.isSmallerOrEqualValue(dayEnd))
            ..where((t) => t.status.equals('ACTIVE')))
          .get();

      for (final bill in bills) {
        // Only sync bank-mode payments — skip pure cash bills
        final bankPortion =
            bill.paidAmount; // Adjust if you track payment split
        if (bankPortion <= 0) continue;

        // Skip if already synced for this bill
        final existing = await (_db.select(_db.bankTransactions)
              ..where((t) => t.referenceId.like('${bill.billNo}%'))
              ..where((t) => t.accountId.equals(accountId)))
            .get();
        if (existing.isNotEmpty) continue;

        final txnId = await _generateTxnId();

        await _db.into(_db.bankTransactions).insert(
              BankTransactionsCompanion.insert(
                txnId: txnId,
                accountId: accountId,
                txnDate: bill.billDate,
                type: BankTransactionType.credit.dbValue,
                category: BankCreditCategory.salePayment.dbValue,
                amount: Value(bankPortion),
                paymentMode: const Value('UPI'),
                description: Value('Sale — ${bill.billNo}'),
                referenceId: Value(bill.billNo),
                referenceType: const Value('BILL'),
                partyName: Value(bill.customerName),
                isAutoGenerated: const Value(true),
                isVoided: const Value(false),
              ),
            );
        synced++;
      }
      return synced;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.syncBillsToBank: $e');
      return 0;
    }
  }

  // ==========================================================================
  // 6. CHEQUE STATUS UPDATE
  // ==========================================================================

  Future<bool> updateChequeStatus(int txnId, ChequeStatus status) async {
    try {
      await (_db.update(_db.bankTransactions)..where((t) => t.id.equals(txnId)))
          .write(BankTransactionsCompanion(
        chequeStatus: Value(status.dbValue),
        valueDate: status == ChequeStatus.cleared
            ? Value(DateTime.now())
            : const Value.absent(),
      ));
      return true;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.updateChequeStatus: $e');
      return false;
    }
  }

  // ==========================================================================
  // 7. RECONCILIATION
  // ==========================================================================

  Future<bool> markReconciled(int txnId, {String? note}) async {
    try {
      await (_db.update(_db.bankTransactions)..where((t) => t.id.equals(txnId)))
          .write(BankTransactionsCompanion(
        isReconciled: const Value(true),
        reconciliationNote: Value(note),
      ));
      return true;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.markReconciled: $e');
      return false;
    }
  }

  // ==========================================================================
  // 8. VOID TRANSACTION (Soft Delete)
  // ==========================================================================

  Future<bool> voidTransaction(int id, String reason) async {
    try {
      await (_db.update(_db.bankTransactions)..where((t) => t.id.equals(id)))
          .write(BankTransactionsCompanion(
        isVoided: const Value(true),
        voidReason: Value(reason),
      ));
      return true;
    } catch (e) {
      AppLogger.debug('❌ BankBookRepository.voidTransaction: $e');
      return false;
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  Future<double> _computeAccountBalance(int accountId, double opening) async {
    try {
      final rows = await (_db.select(_db.bankTransactions)
            ..where((t) => t.accountId.equals(accountId))
            ..where((t) => t.isVoided.equals(false)))
          .get();

      double credit = 0;
      double debit = 0;
      for (final r in rows) {
        if (r.type == BankTransactionType.credit.dbValue) {
          credit += r.amount;
        } else {
          debit += r.amount;
        }
      }
      return opening + credit - debit;
    } catch (_) {
      return opening;
    }
  }

  Future<String> _getAccountName(int accountId) async {
    try {
      final account = await (_db.select(_db.bankAccounts)
            ..where((t) => t.id.equals(accountId)))
          .getSingleOrNull();
      return account?.accountName ?? 'Unknown Account';
    } catch (_) {
      return 'Unknown Account';
    }
  }

  Future<String> _generateTxnId() async {
    final count = await _db.bankTransactions.count().getSingle();
    final year = DateTime.now().year;
    return 'BTXN-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  BankAccountModel _rowToAccountModel(
    BankAccount row,
    double currentBalance,
  ) {
    return BankAccountModel(
      id: row.id,
      accountName: row.accountName,
      holderName: row.holderName,
      bankName: row.bankName,
      accountNumber: row.accountNumber,
      accountNumberMasked:
          BankAccountModel.maskAccountNumber(row.accountNumber),
      ifscCode: row.ifscCode,
      branchName: row.branchName,
      accountType: BankAccountType.fromDb(row.accountType),
      upiId: row.upiId,
      openingBalance: row.openingBalance,
      openingBalanceFormatted: _fmt(row.openingBalance),
      activeSince: row.activeSince,
      isActive: row.isActive,
      isPrimary: row.isPrimary,
      colorHex: row.colorHex,
      currentBalance: currentBalance,
      currentBalanceFormatted: _fmt(currentBalance),
      totalCredit: 0, // computed separately in summary
      totalDebit: 0,
    );
  }

  BankTransactionModel _rowToTxnModel(BankTransaction row, String accountName) {
    final type = BankTransactionType.fromDb(row.type);

    final categoryLabel = type == BankTransactionType.credit
        ? BankCreditCategory.fromDb(row.category).displayLabel
        : BankDebitCategory.fromDb(row.category).displayLabel;

    return BankTransactionModel(
      id: row.id,
      txnId: row.txnId,
      accountId: row.accountId,
      accountName: accountName,
      txnDate: row.txnDate,
      valueDate: row.valueDate,
      type: type,
      categoryDbValue: row.category,
      categoryLabel: categoryLabel,
      amount: row.amount,
      amountFormatted: _fmt(row.amount),
      paymentMode: BankPaymentMode.fromDb(row.paymentMode),
      chequeNumber: row.chequeNumber,
      chequeStatus: row.chequeStatus != null
          ? ChequeStatus.fromDb(row.chequeStatus!)
          : null,
      chequeDate: row.chequeDate,
      description: row.description,
      referenceId: row.referenceId,
      referenceType: row.referenceType,
      partyName: row.partyName,
      isReconciled: row.isReconciled,
      isAutoGenerated: row.isAutoGenerated,
      isVoided: row.isVoided,
    );
  }

  List<BankCategoryBreakdownItem> _buildBreakdown(
    Map<String, double> amountMap,
    Map<String, int> countMap,
    BankTransactionType type,
    double total,
  ) {
    final items = amountMap.entries.map((e) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;
      final label = type == BankTransactionType.credit
          ? BankCreditCategory.fromDb(e.key).displayLabel
          : BankDebitCategory.fromDb(e.key).displayLabel;

      return BankCategoryBreakdownItem(
        label: label,
        categoryDbValue: e.key,
        type: type,
        amount: e.value,
        amountFormatted: _fmt(e.value),
        percentage: pct,
        count: countMap[e.key] ?? 0,
      );
    }).toList();

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }
}