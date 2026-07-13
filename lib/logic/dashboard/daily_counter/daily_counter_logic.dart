// =============================================================================
// FILE        : daily_counter_logic.dart
// MODULE      : Dashboard / Daily Counter Activity
// LAYER       : Logic
// DESCRIPTION : Aaj ke counter activity ka poora data Drift DB se.
//
//               DATA SOURCES:
//               METAL SOLD:
//                 → BillItems (aaj ke bills) + Bills (billDate = today)
//                 → group by purity type → GOLD = 22K/18K/24K, SILVER = 925/Silver
//                 → sum grossWeight, count items
//
//               METAL BOUGHT (Stock added today):
//                 → StockItems (createdAt = today, status = Available)
//                 → group by metalType
//
//               NEW DUE:
//                 → Bills (aaj ki date, paidAmount < finalAmount)
//                 → count customers + sum due amount
//
//               NEW GIRVI/LOAN:
//                 → Loans (startDate = today)
//                 → count + sum loanAmount
//
//               Pattern: StreamController (BillCardLogic jaisa)
// =============================================================================

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../../models/dashboard/daily_counter_model.dart';
import '../../../core/logging/app_logger.dart';

class DailyCounterLogic {
  final AppDatabase _db;
  DailyCounterLogic({AppDatabase? db}) : _db = db ?? AppDatabase();

  // Stream controller
  final _controller = StreamController<DailyCounterModel>.broadcast();
  Stream<DailyCounterModel> get dataStream => _controller.stream;

  // All subscriptions
  final List<StreamSubscription> _subs = [];

  // ==========================================
  // INIT — Start watching all tables
  // ==========================================
  void init() {
    _startWatching();
  }

  void _startWatching() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Watch BillItems (for metal sold)
    _subs.add(
      (_db.select(_db.billItems)).watch().listen(
            (_) => _refresh(todayStart, todayEnd),
            onError: (e) => AppLogger.debug('❌ DailyCounter BillItems error: $e'),
          ),
    );

    // Watch StockItems (for metal bought/added today)
    _subs.add(
      (_db.select(_db.stockItems)).watch().listen(
            (_) => _refresh(todayStart, todayEnd),
            onError: (e) => AppLogger.debug('❌ DailyCounter StockItems error: $e'),
          ),
    );

    // Watch Bills (for new due)
    _subs.add(
      (_db.select(_db.bills)).watch().listen(
            (_) => _refresh(todayStart, todayEnd),
            onError: (e) => AppLogger.debug('❌ DailyCounter Bills error: $e'),
          ),
    );

    // Watch Loans (for new girvi)
    _subs.add(
      (_db.select(_db.loans)).watch().listen(
            (_) => _refresh(todayStart, todayEnd),
            onError: (e) => AppLogger.debug('❌ DailyCounter Loans error: $e'),
          ),
    );

    // First fetch immediately
    _refresh(todayStart, todayEnd);
  }

  // ==========================================
  // REFRESH — Sab data ek saath fetch karo
  // ==========================================
  Future<void> _refresh(DateTime todayStart, DateTime todayEnd) async {
    try {
      final results = await Future.wait([
        _fetchMetalMovement(todayStart, todayEnd),
        _fetchFinanceDue(todayStart, todayEnd),
      ]);

      final now = DateTime.now();
      final fmt = DateFormat('MMM dd, yyyy');
      final model = DailyCounterModel(
        dateStr: fmt.format(now),
        metalMovement: results[0] as MetalMovementData,
        financeDue: results[1] as FinanceDueData,
      );

      if (!_controller.isClosed) _controller.add(model);
    } catch (e) {
      AppLogger.debug('❌ DailyCounter refresh error: $e');
      if (!_controller.isClosed) {
        _controller.add(DailyCounterModel.empty(
          DateFormat('MMM dd, yyyy').format(DateTime.now()),
        ));
      }
    }
  }

  // ==========================================
  // METAL MOVEMENT
  // ==========================================
  Future<MetalMovementData> _fetchMetalMovement(
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    // Aaj ke active bills fetch karo
    final todayBills = await (_db.select(_db.bills)
          ..where((t) => t.billDate.isBiggerOrEqualValue(todayStart))
          ..where((t) => t.billDate.isSmallerOrEqualValue(todayEnd))
          ..where((t) => t.status.equals('ACTIVE')))
        .get();

    final todayBillIds = todayBills.map((b) => b.id).toList();

    double soldGoldWt = 0, soldSilverWt = 0;
    int soldGoldPcs = 0, soldSilverPcs = 0;

    if (todayBillIds.isNotEmpty) {
      // BillItems from today's bills
      final billItems = await (_db.select(_db.billItems)
            ..where((t) => t.billId.isIn(todayBillIds)))
          .get();

      for (final item in billItems) {
        final purity = item.purity.toUpperCase();
        // Gold puritites: 24K, 22K, 18K, 14K
        final isGold = purity.contains('K') ||
            purity.contains('GOLD') ||
            purity.contains('KT');
        // Silver purities: 925, 999, SILVER
        final isSilver = purity.contains('925') ||
            purity.contains('999') ||
            purity.contains('SILVER');

        if (isGold) {
          soldGoldWt += item.grossWeight;
          soldGoldPcs += 1;
        } else if (isSilver) {
          soldSilverWt += item.grossWeight;
          soldSilverPcs += 1;
        } else {
          // Default: gold maan lo
          soldGoldWt += item.grossWeight;
          soldGoldPcs += 1;
        }
      }
    }

    // Metal Bought — StockItems aaj create kiye gaye
    final todayStock = await (_db.select(_db.stockItems)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(todayStart))
          ..where((t) => t.createdAt.isSmallerOrEqualValue(todayEnd)))
        .get();

    double boughtGoldWt = 0, boughtSilverWt = 0;
    int boughtGoldPcs = 0, boughtSilverPcs = 0;

    for (final item in todayStock) {
      final metal = item.metalType.toUpperCase();
      if (metal.contains('GOLD')) {
        boughtGoldWt += item.grossWeight;
        boughtGoldPcs += item.quantity;
      } else if (metal.contains('SILVER')) {
        boughtSilverWt += item.grossWeight;
        boughtSilverPcs += item.quantity;
      }
    }

    return MetalMovementData(
      soldGold: _makeEntry(soldGoldWt, soldGoldPcs),
      soldSilver: _makeEntry(soldSilverWt, soldSilverPcs),
      boughtGold: _makeEntry(boughtGoldWt, boughtGoldPcs),
      boughtSilver: _makeEntry(boughtSilverWt, boughtSilverPcs),
    );
  }

  // ==========================================
  // FINANCE & DUE
  // ==========================================
  Future<FinanceDueData> _fetchFinanceDue(
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    // New Due — aaj ke bills jinka payment pending hai
    final todayBills = await (_db.select(_db.bills)
          ..where((t) => t.billDate.isBiggerOrEqualValue(todayStart))
          ..where((t) => t.billDate.isSmallerOrEqualValue(todayEnd))
          ..where((t) => t.status.equals('ACTIVE')))
        .get();

    int dueCustCount = 0;
    double dueTotal = 0;

    for (final bill in todayBills) {
      final computedDue = bill.finalAmount - bill.paidAmount;
      final due = bill.dueAmount > 0.5 ? bill.dueAmount : computedDue;
      if (due > 0) {
        dueCustCount++;
        dueTotal += due;
      }
    }

    // New Girvi/Loans — aaj create kiye
    final todayLoans = await (_db.select(_db.loans)
          ..where((t) => t.startDate.isBiggerOrEqualValue(todayStart))
          ..where((t) => t.startDate.isSmallerOrEqualValue(todayEnd)))
        .get();

    final girviCount = todayLoans.length;
    final girviTotal = todayLoans.fold<double>(
      0,
      (sum, l) => sum + l.loanAmount,
    );

    return FinanceDueData(
      dueCount: dueCustCount == 0
          ? '0 Customers'
          : '$dueCustCount Customer${dueCustCount > 1 ? 's' : ''}',
      dueAmount: _formatAmount(dueTotal),
      girviCount: girviCount == 0
          ? '0 Loans'
          : '$girviCount New Loan${girviCount > 1 ? 's' : ''}',
      girviAmount: _formatAmount(girviTotal),
      dueAmountRaw: dueTotal,
      girviAmountRaw: girviTotal,
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================
  MetalEntry _makeEntry(double weight, int pieces) {
    return MetalEntry(
      weightStr: '${weight.toStringAsFixed(3)} gm',
      piecesStr: pieces == 1 ? '1 Pc' : '$pieces Pcs',
      weightRaw: weight,
    );
  }

  static String _formatAmount(double amount) {
    if (amount == 0) return '₹0';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  // ==========================================
  // CLEANUP
  // ==========================================
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _controller.close();
  }

  DailyCounterModel get initialData => DailyCounterModel.loading();
}