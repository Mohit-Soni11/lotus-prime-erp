// =============================================================================
// FILE        : cash_register_logic.dart
// MODULE      : Dashboard / Cash Register
// LAYER       : Logic
// DESCRIPTION : Cash Register Card — live financial snapshot.
//
//               v2 UPGRADE — Fully connected to Cash Book:
//               totalReceived  → Bills.paidAmount (POS, real-time)
//               totalPaidOut   → CashTransactions EXPENSE sum (real-time)
//               netCashDrawer  → openingBalance + received - paidOut
//
//               Both Bills AND CashTransactions are watched simultaneously.
//               Any change in either table triggers an instant recalculation.
//
//               FORMULA:
//               Net Cash In Drawer =
//                   Opening Balance
//                   + Total Sales Received (from Bills)
//                   - Total Expenses (from CashTransactions)
// =============================================================================

import 'dart:async';
import 'package:intl/intl.dart';

import 'package:drift/drift.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/dashboard/cash_register_model.dart';
import '../../../core/logging/app_logger.dart';

class CashRegisterLogic {
  final AppDatabase _db;
  CashRegisterLogic({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ── Stream ─────────────────────────────────────────────────────────────────
  final _controller = StreamController<CashRegisterModel>.broadcast();
  Stream<CashRegisterModel> get dataStream => _controller.stream;

  StreamSubscription? _incomeSub;
  StreamSubscription? _expenseSub;
  Timer? _dayRolloverTimer;

  // ── Today's range (set once at init, stable for the day) ──────────────────
  late final DateTime _todayStart;
  late final DateTime _todayEnd;

  // ── Cached values for combined compute ────────────────────────────────────
  double _cachedReceived = 0.0;
  double _cachedExpense = 0.0;
  bool _isComputing = false;
  bool _recomputePending = false;

  // ==========================================
  // INIT
  // ==========================================

  void init() {
    _setCurrentDay();
    _startLiveWatch();
    _scheduleDayRollover();
  }

  void _setCurrentDay() {
    final now = DateTime.now();
    _todayStart = DateTime(now.year, now.month, now.day);
    _todayEnd = DateTime(now.year, now.month, now.day + 1);
  }

  void _scheduleDayRollover() {
    _dayRolloverTimer?.cancel();
    final delay = _todayEnd.difference(DateTime.now());
    _dayRolloverTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      _incomeSub?.cancel();
      _expenseSub?.cancel();
      _cachedReceived = 0;
      _cachedExpense = 0;
      _setCurrentDay();
      _startLiveWatch();
      _scheduleDayRollover();
    });
  }

  void _startLiveWatch() {
    // ── Watch 1: Bills → totalReceived ──────────────────────────────────────
    _incomeSub = (_db.select(_db.cashTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.type.equals(CashTransactionType.income.dbValue))
          ..where((t) => t.paymentMode.equals(PaymentMode.cash.dbValue))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(_todayStart))
          ..where((t) => t.txnDate.isSmallerThanValue(_todayEnd)))
        .watch()
        .listen(
      (txns) {
        _cachedReceived = txns.fold(0.0, (sum, t) => sum + t.amount);
        _emitComputed();
      },
      onError: (e) {
        AppLogger.debug('CashRegister income watch error: $e');
        _emitFallback();
      },
    );

    // ── Watch 2: CashTransactions EXPENSE → totalPaidOut ────────────────────
    _expenseSub = (_db.select(_db.cashTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.type.equals(CashTransactionType.expense.dbValue))
          ..where((t) => t.paymentMode.equals(PaymentMode.cash.dbValue))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(_todayStart))
          ..where((t) => t.txnDate.isSmallerThanValue(_todayEnd)))
        .watch()
        .listen(
      (txns) {
        _cachedExpense = txns.fold(0.0, (sum, t) => sum + t.amount);
        _emitComputed();
      },
      onError: (e) {
        AppLogger.debug('CashRegister expense watch error: $e');
      },
    );
  }

  // ==========================================
  // COMPUTE & EMIT
  // ==========================================

  Future<void> _emitComputed() async {
    // Avoid overlapping calculations when both streams fire at the same time.
    if (_controller.isClosed) return;
    if (_isComputing) {
      _recomputePending = true;
      return;
    }
    _isComputing = true;

    try {
      double openingBalance = 0.0;
      try {
        final shop =
            await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
        openingBalance = shop?.openingCashBalance ?? 0.0;
      } catch (_) {}

      final prior = await _db.customSelect(
        '''SELECT COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount
            WHEN type = 'EXPENSE' THEN -amount ELSE 0 END), 0) AS movement
           FROM cash_transactions
           WHERE is_voided = 0 AND payment_mode = 'CASH' AND txn_date < ?''',
        variables: [Variable.withDateTime(_todayStart)],
      ).getSingle();
      openingBalance += prior.read<double>('movement');
      final netCash = openingBalance + _cachedReceived - _cachedExpense;

      if (!_controller.isClosed) {
        _controller.add(CashRegisterModel(
          openingBalance: openingBalance,
          totalReceived: _cachedReceived,
          totalPaidOut: _cachedExpense,
          netCashDrawer: netCash,
          openingBalanceStr: _fmt(openingBalance),
          totalReceivedStr: _fmt(_cachedReceived),
          totalPaidOutStr: _fmt(_cachedExpense),
          netCashDrawerStr: _fmt(netCash),
        ));
      }
    } catch (e) {
      AppLogger.debug('CashRegister compute error: $e');
      _emitFallback();
    } finally {
      _isComputing = false;
      if (_recomputePending) {
        _recomputePending = false;
        _emitComputed();
      }
    }
  }

  void _emitFallback() {
    if (!_controller.isClosed) {
      _controller.add(CashRegisterModel.zero());
    }
  }

  // ==========================================
  // FORMATTER
  // ==========================================

  static String _fmt(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    ).format(amount);
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  void dispose() {
    _dayRolloverTimer?.cancel();
    _incomeSub?.cancel();
    _expenseSub?.cancel();
    _controller.close();
  }

  CashRegisterModel get initialData => CashRegisterModel.loading();
}
