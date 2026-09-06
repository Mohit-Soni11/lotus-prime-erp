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
//                 → Customer old metal entered in today's bills
//                 → Sales return vouchers posted today (physical metal received)
//                 → group by metalType using net received weight
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

  static const double _amountTolerance = 0.005;
  static const List<String> _billLifecycleStatuses = [
    'ACTIVE',
    'PARTIALLY_RETURNED',
    'RETURNED',
  ];

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
            onError: (e) =>
                AppLogger.debug('❌ DailyCounter BillItems error: $e'),
          ),
    );

    // Watch customer old metal entries (exchange/purchase settlement).
    _subs.add(
      (_db.select(_db.billTradeInItems)).watch().listen(
            (_) => _refresh(todayStart, todayEnd),
            onError: (e) => AppLogger.debug('❌ DailyCounter TradeIn error: $e'),
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
          ..where((t) => t.status.isIn(_billLifecycleStatuses)))
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
        final metal = item.metalType.trim().toUpperCase();
        if (metal.contains('SILVER')) {
          soldSilverWt += item.grossWeight;
          soldSilverPcs += item.quantity;
        } else if (metal.contains('GOLD')) {
          soldGoldWt += item.grossWeight;
          soldGoldPcs += item.quantity;
        }
      }
    }

    double boughtGoldWt = 0, boughtSilverWt = 0;
    int boughtGoldPcs = 0, boughtSilverPcs = 0;

    if (todayBillIds.isNotEmpty) {
      final tradeInItems = await (_db.select(_db.billTradeInItems)
            ..where((t) => t.billId.isIn(todayBillIds)))
          .get();

      for (final item in tradeInItems) {
        final metal = item.metalType.trim().toUpperCase();
        if (metal.contains('SILVER')) {
          boughtSilverWt += item.grossWeight;
          boughtSilverPcs += 1;
        } else if (metal.contains('GOLD')) {
          boughtGoldWt += item.grossWeight;
          boughtGoldPcs += 1;
        }
      }
    }

    final customerPurchaseReceipts = await _fetchCustomerPurchaseMetalReceipts(
      todayStart,
      todayEnd,
    );
    boughtGoldWt += customerPurchaseReceipts.goldWeight;
    boughtGoldPcs += customerPurchaseReceipts.goldPieces;
    boughtSilverWt += customerPurchaseReceipts.silverWeight;
    boughtSilverPcs += customerPurchaseReceipts.silverPieces;

    final returnedReceipts = await _fetchSalesReturnMetalReceipts(
      todayStart,
      todayEnd,
    );
    boughtGoldWt += returnedReceipts.goldWeight;
    boughtGoldPcs += returnedReceipts.goldPieces;
    boughtSilverWt += returnedReceipts.silverWeight;
    boughtSilverPcs += returnedReceipts.silverPieces;

    return MetalMovementData(
      soldGold: _makeEntry(soldGoldWt, soldGoldPcs),
      soldSilver: _makeEntry(soldSilverWt, soldSilverPcs),
      boughtGold: _makeEntry(boughtGoldWt, boughtGoldPcs),
      boughtSilver: _makeEntry(boughtSilverWt, boughtSilverPcs),
    );
  }

  Future<_MetalReceiptTotals> _fetchCustomerPurchaseMetalReceipts(
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    await _db.ensureReturnReversalSchema();
    final startMs = todayStart.millisecondsSinceEpoch;
    final endMs = todayEnd.millisecondsSinceEpoch;
    final rows = await _db.customSelect(
      '''
      SELECT
        pvi.metal_type,
        COALESCE(SUM(pvi.net_weight), 0.0) AS received_net_weight,
        COALESCE(SUM(pvi.quantity), 0) AS received_quantity
      FROM purchase_voucher_items pvi
      INNER JOIN purchase_vouchers pv ON pv.id = pvi.purchase_voucher_id
      WHERE pv.source_type = 'CUSTOMER'
        AND pv.status <> 'CANCELLED'
        AND pv.payment_status <> 'RETURN_MELTING'
        AND pv.voucher_no NOT LIKE 'MELT-%'
        AND pv.created_at BETWEEN ? AND ?
      GROUP BY UPPER(TRIM(pvi.metal_type))
      ''',
      variables: [
        Variable.withInt(startMs),
        Variable.withInt(endMs),
      ],
    ).get();

    return _receiptTotalsFromRows(rows);
  }

  Future<_MetalReceiptTotals> _fetchSalesReturnMetalReceipts(
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    await _db.ensureReturnReversalSchema();
    final startMs = todayStart.millisecondsSinceEpoch;
    final endMs = todayEnd.millisecondsSinceEpoch;
    final rows = await _db.customSelect(
      '''
      SELECT
        l.metal_type,
        COALESCE(SUM(l.received_net_weight), 0.0) AS received_net_weight,
        COALESCE(SUM(l.quantity), 0) AS received_quantity
      FROM return_voucher_lines l
      INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
      WHERE v.operation_type = 'SALES_RETURN'
        AND v.source_type = 'SALES_INVOICE'
        AND v.status <> 'VOIDED'
        AND l.status <> 'VOIDED'
        AND l.created_at BETWEEN ? AND ?
      GROUP BY UPPER(TRIM(l.metal_type))
      ''',
      variables: [
        Variable.withInt(startMs),
        Variable.withInt(endMs),
      ],
    ).get();

    return _receiptTotalsFromRows(rows);
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
          ..where((t) => t.status.isIn(_billLifecycleStatuses)))
        .get();

    final dueCustomers = <String>{};
    double dueTotal = 0;

    for (final bill in todayBills) {
      final due = _currentDue(bill);
      if (due > _amountTolerance) {
        dueCustomers.add(_dueCustomerKey(bill));
        dueTotal += due;
      }
    }
    final dueCustCount = dueCustomers.length;

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

  double _readDouble(QueryRow row, String column) {
    final value = row.data[column];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 0;
  }

  _MetalReceiptTotals _receiptTotalsFromRows(List<QueryRow> rows) {
    var goldWeight = 0.0;
    var silverWeight = 0.0;
    var goldPieces = 0;
    var silverPieces = 0;

    for (final row in rows) {
      final metal = row.readNullable<String>('metal_type')?.toUpperCase() ?? '';
      final weight = _readDouble(row, 'received_net_weight');
      final pieces = row.readNullable<int>('received_quantity') ?? 0;
      if (metal.contains('SILVER')) {
        silverWeight += weight;
        silverPieces += pieces;
      } else if (metal.contains('GOLD')) {
        goldWeight += weight;
        goldPieces += pieces;
      }
    }

    return _MetalReceiptTotals(
      goldWeight: goldWeight,
      goldPieces: goldPieces,
      silverWeight: silverWeight,
      silverPieces: silverPieces,
    );
  }

  String _dueCustomerKey(Bill bill) {
    if (bill.customerId != null) return 'ID:${bill.customerId}';
    final mobile = bill.mobile?.trim();
    if (mobile != null && mobile.isNotEmpty) return 'M:$mobile';
    final name = bill.customerName?.trim();
    if (name != null && name.isNotEmpty) return 'N:$name';
    return 'B:${bill.id}';
  }

  double _currentDue(Bill bill) {
    final paymentStatus = bill.paymentStatus.trim().toUpperCase();
    if (paymentStatus == 'PAID' ||
        paymentStatus == 'SETTLED' ||
        paymentStatus == 'COMPLETE' ||
        paymentStatus == 'COMPLETED') {
      return 0;
    }
    if (bill.dueAmount > _amountTolerance ||
        paymentStatus == 'PARTIAL' ||
        paymentStatus == 'DUE' ||
        paymentStatus == 'UNPAID') {
      return bill.dueAmount.clamp(0.0, double.infinity).toDouble();
    }
    return (bill.finalAmount - bill.paidAmount)
        .clamp(0.0, double.infinity)
        .toDouble();
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

class _MetalReceiptTotals {
  final double goldWeight;
  final int goldPieces;
  final double silverWeight;
  final int silverPieces;

  const _MetalReceiptTotals({
    required this.goldWeight,
    required this.goldPieces,
    required this.silverWeight,
    required this.silverPieces,
  });
}
