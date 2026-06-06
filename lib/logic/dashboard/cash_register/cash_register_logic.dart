// =============================================================================
// FILE        : cash_register_logic.dart
// MODULE      : Dashboard / Cash Register
// LAYER       : Logic
// DESCRIPTION : Cash Register Card — live financial snapshot.
//
//               v2 UPGRADE — Fully connected to Cash Book:
//               ✅ totalReceived  → Bills.paidAmount (POS, real-time)
//               ✅ totalPaidOut   → CashTransactions EXPENSE sum (real-time)
//               ✅ netCashDrawer  → openingBalance + received - paidOut
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
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// FIX: Added drift import to access ComparableExpr extension methods
import 'package:drift/drift.dart';

import '../../../database/db/app_database.dart';
import '../../../models/finance/cash_book/cash_book_enums.dart';
import '../../../models/dashboard/cash_register_model.dart';

class CashRegisterLogic {
  final AppDatabase _db;
  CashRegisterLogic({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ── Stream ─────────────────────────────────────────────────────────────────
  final _controller = StreamController<CashRegisterModel>.broadcast();
  Stream<CashRegisterModel> get dataStream => _controller.stream;

  StreamSubscription? _incomeSub;
  StreamSubscription? _expenseSub;

  // ── Today's range (set once at init, stable for the day) ──────────────────
  late final DateTime _todayStart;
  late final DateTime _todayEnd;

  // ── Cached values for combined compute ────────────────────────────────────
  double _cachedReceived = 0.0;
  double _cachedExpense = 0.0;
  bool _isComputing = false; // ✅ BUG FIX: prevent race condition

  // ==========================================
  // INIT
  // ==========================================

  void init() {
    final now = DateTime.now();
    _todayStart = DateTime(now.year, now.month, now.day);
    _todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _startLiveWatch();
  }

  void _startLiveWatch() {
    // ── Watch 1: Bills → totalReceived ──────────────────────────────────────
    _incomeSub = (_db.select(_db.cashTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.type.equals(CashTransactionType.income.dbValue))
          ..where((t) => t.paymentMode.equals(PaymentMode.cash.dbValue))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(_todayStart))
          ..where((t) => t.txnDate.isSmallerOrEqualValue(_todayEnd)))
        .watch()
        .listen(
      (txns) {
        _cachedReceived = txns.fold(0.0, (sum, t) => sum + t.amount);
        _emitComputed();
      },
      onError: (e) {
        debugPrint('CashRegister income watch error: $e');
        _emitFallback();
      },
    );

    // ── Watch 2: CashTransactions EXPENSE → totalPaidOut ────────────────────
    _expenseSub = (_db.select(_db.cashTransactions)
          ..where((t) => t.isVoided.equals(false))
          ..where((t) => t.type.equals(CashTransactionType.expense.dbValue))
          ..where((t) => t.paymentMode.equals(PaymentMode.cash.dbValue))
          ..where((t) => t.txnDate.isBiggerOrEqualValue(_todayStart))
          ..where((t) => t.txnDate.isSmallerOrEqualValue(_todayEnd)))
        .watch()
        .listen(
      (txns) {
        _cachedExpense = txns.fold(0.0, (sum, t) => sum + t.amount);
        _emitComputed();
      },
      onError: (e) {
        debugPrint('❌ CashRegister Expense watch error: $e');
      },
    );
  }

  // ==========================================
  // COMPUTE & EMIT
  // ==========================================

  Future<void> _emitComputed() async {
    // ✅ BUG FIX: If already computing (race condition when both streams fire
    // simultaneously), skip — the in-flight compute will use latest cached values
    if (_isComputing || _controller.isClosed) return;
    _isComputing = true;

    try {
      double openingBalance = 0.0;
      try {
        final shop =
            await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
        openingBalance = shop?.openingCashBalance ?? 0.0;
      } catch (_) {}

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
      debugPrint('❌ CashRegister compute error: $e');
      _emitFallback();
    } finally {
      _isComputing = false;
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
    _incomeSub?.cancel();
    _expenseSub?.cancel();
    _controller.close();
  }

  CashRegisterModel get initialData => CashRegisterModel.loading();
}
