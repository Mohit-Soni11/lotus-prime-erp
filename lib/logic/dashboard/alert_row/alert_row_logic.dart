// =============================================================================
// FILE        : alert_row_logic.dart
// MODULE      : Dashboard / Alert Row
// LAYER       : Logic (Business Logic)
// DESCRIPTION : Charon alert cards ka data Drift DB se fetch karta hai.
//               Live stream watch karta hai — data change hone par auto-update.
//
//               CARD 1 — INVENTORY:
//                 StockItems → Gold/Silver items count
//                 Low stock (qty <= 2) → WARNING
//                 Out of stock (qty == 0) → CRITICAL
//
//               CARD 2 — PENDING ORDERS:
//                 SalesOrders → PENDING status
//                 deliveryDate < today → LATE (CRITICAL)
//                 deliveryDate == today → DUE TODAY (WARNING)
//                 All on time → SAFE
//
//               CARD 3 — COLLECTIONS:
//                 Bills (ACTIVE) + Loans (ACTIVE) → total outstanding
//                 Any active → WARNING
//                 None → SAFE
//
//               CARD 4 — DELIVERIES:
//                 SalesOrders → min(deliveryDate) where PENDING
//                 Past date → MISSED (CRITICAL)
//                 Today → TODAY (WARNING)
//                 Future → ON SCHEDULE (SAFE)
//
//               Pattern: ChangeNotifier (ShopCardLogic / BillCardLogic jaisa)
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../database/db/app_database.dart';
import '../../../models/dashboard/alert_card_model.dart';
import '../../../constants/app_routes.dart';

// ── Stock Thresholds (Python ke GOLD_MIN, GOLD_HALF jaisa) ────────────────────
const int _kGoldCriticalQty = 3; // Items <= yeh → CRITICAL
const int _kGoldWarningQty = 8; // Items <= yeh → WARNING
const int _kSilverCriticalQty = 5;
const int _kSilverWarningQty = 12;

class AlertRowLogic extends ChangeNotifier {
  // ── Dependencies ─────────────────────────────────────────────────────────────
  final AppDatabase _db;
  AlertRowLogic({AppDatabase? db}) : _db = db ?? AppDatabase() {
    _startLiveWatch();
  }

  // ── State ─────────────────────────────────────────────────────────────────────
  AlertRowModel _data = _buildLoadingState();
  bool _hasError = false;

  AlertRowModel get data => _data;
  bool get hasError => _hasError;
  bool get isLoading => _data.cards.any((c) => c.isLoading);

  // ── Live Stream subscriptions ─────────────────────────────────────────────────
  final List<StreamSubscription> _subs = [];

  // ==========================================
  // MAIN: Start watching all 4 DB streams
  // ==========================================
  void _startLiveWatch() {
    // Watch StockItems for Inventory card
    _subs.add(
      _db.select(_db.stockItems).watch().listen(
            (_) => _refresh(),
            onError: (_) => _onError(),
          ),
    );

    // Watch SalesOrders for Orders + Deliveries cards
    _subs.add(
      _db.select(_db.salesOrders).watch().listen(
            (_) => _refresh(),
            onError: (_) => _onError(),
          ),
    );

    // Watch Bills for Collections card
    _subs.add(
      _db.select(_db.bills).watch().listen(
            (_) => _refresh(),
            onError: (_) => _onError(),
          ),
    );

    // Watch Loans for Collections card
    _subs.add(
      _db.select(_db.loans).watch().listen(
            (_) => _refresh(),
            onError: (_) => _onError(),
          ),
    );

    // First fetch immediately
    _refresh();
  }

  // ==========================================
  // REFRESH — Sab 4 cards ko ek saath update karo
  // ==========================================
  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _buildInventoryCard(),
        _buildOrdersCard(),
        _buildCollectionsCard(),
        _buildDeliveriesCard(),
      ]);

      _data = AlertRowModel(
        inventory: results[0],
        orders: results[1],
        collections: results[2],
        deliveries: results[3],
      );
      _hasError = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AlertRowLogic Error: $e');
      _onError();
    }
  }

  void _onError() {
    _hasError = true;
    notifyListeners();
  }

  // ==========================================
  // CARD 1 — INVENTORY
  // StockItems table se Gold/Silver ka stock check karo
  // ==========================================
  Future<AlertCardModel> _buildInventoryCard() async {
    // All available stock items fetch karo
    final allItems = await (_db.select(_db.stockItems)
          ..where((t) => t.status.equals('Available')))
        .get();

    // Gold aur Silver alag karo
    final goldItems =
        allItems.where((i) => i.metalType.toLowerCase() == 'gold').toList();
    final silverItems =
        allItems.where((i) => i.metalType.toLowerCase() == 'silver').toList();

    // Total quantities
    final goldQty = goldItems.fold<int>(0, (sum, i) => sum + i.quantity);
    final silverQty = silverItems.fold<int>(0, (sum, i) => sum + i.quantity);

    // Status decide karo — Python jaisa 2-level check
    final gStat = goldQty <= _kGoldCriticalQty
        ? 2
        : goldQty <= _kGoldWarningQty
            ? 1
            : 0;

    final sStat = silverQty <= _kSilverCriticalQty
        ? 2
        : silverQty <= _kSilverWarningQty
            ? 1
            : 0;

    // Combined status + message (Python jaisi exact logic)
    String mainValue;
    String subText;
    AlertStatus status;

    if (gStat == 2 && sStat == 2) {
      status = AlertStatus.critical;
      mainValue = 'ALL CRITICAL';
      subText = 'Gold & Silver dono low';
    } else if (gStat == 2) {
      status = AlertStatus.critical;
      mainValue = 'GOLD LOW';
      subText = 'Turant restock karo';
    } else if (sStat == 2) {
      status = AlertStatus.critical;
      mainValue = 'SILVER LOW';
      subText = 'Turant restock karo';
    } else if (gStat == 1 || sStat == 1) {
      status = AlertStatus.warning;
      mainValue = 'REFILL SOON';
      subText = 'Limit ke paas aa raha hai';
    } else if (allItems.isEmpty) {
      status = AlertStatus.critical;
      mainValue = 'NO STOCK';
      subText = 'Koi item available nahi';
    } else {
      status = AlertStatus.safe;
      mainValue = 'STOCK HEALTHY';
      mainValue = '${allItems.length} Items';
      subText = 'Inventory optimal hai';
    }

    return AlertCardModel(
      id: 'inventory',
      title: 'Inventory',
      mainValue: mainValue,
      subText: subText,
      status: status,
      routeId: AppRoutes.inventoryRoute,
    );
  }

  // ==========================================
  // CARD 2 — PENDING ORDERS
  // SalesOrders → PENDING wale orders check karo
  // deliveryDate vs today compare karo
  // ==========================================
  Future<AlertCardModel> _buildOrdersCard() async {
    final pendingOrders = await (_db.select(_db.salesOrders)
          ..where((t) => t.status.equals('PENDING')))
        .get();

    final int total = pendingOrders.length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Overdue orders — delivery date nikal gayi
    final overdueOrders = pendingOrders.where((o) {
      if (o.deliveryDate == null) return false;
      final delDate = DateTime(
        o.deliveryDate!.year,
        o.deliveryDate!.month,
        o.deliveryDate!.day,
      );
      return delDate.isBefore(today);
    }).toList();

    // Due today
    final dueTodayOrders = pendingOrders.where((o) {
      if (o.deliveryDate == null) return false;
      final delDate = DateTime(
        o.deliveryDate!.year,
        o.deliveryDate!.month,
        o.deliveryDate!.day,
      );
      return delDate.isAtSameMomentAs(today);
    }).toList();

    // Status logic (Python ke karigar_delay_days jaisa)
    String mainValue;
    String subText;
    AlertStatus status;

    if (overdueOrders.isNotEmpty) {
      status = AlertStatus.critical;
      mainValue = 'LATE: ${overdueOrders.length}';
      subText = '${overdueOrders.length} order overdue hai';
    } else if (dueTodayOrders.isNotEmpty) {
      status = AlertStatus.warning;
      mainValue = 'DUE TODAY';
      subText = '${dueTodayOrders.length} order deliver karo';
    } else if (total == 0) {
      status = AlertStatus.safe;
      mainValue = 'NO ORDERS';
      subText = 'Koi pending order nahi';
    } else {
      status = AlertStatus.safe;
      mainValue = '$total Pending';
      subText = 'Sab orders on time';
    }

    return AlertCardModel(
      id: 'orders',
      title: 'Orders',
      mainValue: mainValue,
      subText: subText,
      status: status,
      routeId: AppRoutes.pendingJobsRoute,
    );
  }

  // ==========================================
  // CARD 3 — COLLECTIONS
  // Bills (ACTIVE) + Loans (ACTIVE) → outstanding
  // ==========================================
  Future<AlertCardModel> _buildCollectionsCard() async {
    // Active bills count
    final activeBills = await (_db.select(_db.bills)
          ..where((t) => t.status.equals('ACTIVE')))
        .get();

    // Active loans count
    final activeLoans = await (_db.select(_db.loans)
          ..where((t) => t.status.equals('ACTIVE')))
        .get();

    final int billCount = activeBills.length;
    final int loanCount = activeLoans.length;
    final int total = billCount + loanCount;

    // Total outstanding amount (bills ka)
    final double totalAmt = activeBills.fold<double>(
      0.0,
      (sum, b) => sum + b.finalAmount,
    );

    // Format amount — Indian style
    final formattedAmt = _formatIndianCurrency(totalAmt);

    // Status logic (Python ke due_bills_count jaisa)
    String mainValue;
    String subText;
    AlertStatus status;

    if (total == 0) {
      status = AlertStatus.safe;
      mainValue = 'ALL CLEAR';
      subText = 'Koi due nahi hai';
    } else if (loanCount > 0 && billCount > 0) {
      status = AlertStatus.warning;
      mainValue = formattedAmt;
      subText = '$billCount bills + $loanCount loans active';
    } else if (billCount > 0) {
      status = AlertStatus.warning;
      mainValue = formattedAmt;
      subText = '$billCount active bills due';
    } else {
      status = AlertStatus.warning;
      mainValue = '$loanCount Loans';
      subText = 'Active girvi/loans';
    }

    return AlertCardModel(
      id: 'collections',
      title: 'Collections',
      mainValue: mainValue,
      subText: subText,
      status: status,
      routeId: AppRoutes.dueReportRoute,
    );
  }

  // ==========================================
  // CARD 4 — DELIVERIES
  // SalesOrders → next delivery date dhundho
  // Python ke delivery_pending_days jaisi logic
  // ==========================================
  Future<AlertCardModel> _buildDeliveriesCard() async {
    // ✅ FIX: Drift mein & operator kaam nahi karta ek where mein
    //    Solution: 2 alag ..where() calls — exactly BillCardLogic jaisa
    final pendingWithDate = await (_db.select(_db.salesOrders)
          ..where((t) => t.status.equals('PENDING'))
          ..where((t) => t.deliveryDate.isNotNull()))
        .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String mainValue;
    String subText;
    AlertStatus status;

    if (pendingWithDate.isEmpty) {
      status = AlertStatus.safe;
      mainValue = 'NO DUE';
      subText = 'Koi delivery pending nahi';
    } else {
      // Minimum delivery date dhundho (next delivery)
      final sortedDates = pendingWithDate
          .map((o) => DateTime(
                o.deliveryDate!.year,
                o.deliveryDate!.month,
                o.deliveryDate!.day,
              ))
          .toList()
        ..sort();

      final nextDelivery = sortedDates.first;
      final diff = nextDelivery.difference(today).inDays;

      // Overdue count
      final overdueCount = sortedDates.where((d) => d.isBefore(today)).length;

      if (diff < 0 || overdueCount > 0) {
        // Python: delivery_pending_days > 0 → MISSED
        status = AlertStatus.critical;
        mainValue = overdueCount > 1 ? '$overdueCount MISSED' : 'MISSED';
        subText = '$overdueCount delivery overdue';
      } else if (diff == 0) {
        // Python: delivery_pending_days == 0 → TODAY
        status = AlertStatus.warning;
        mainValue = 'TODAY';
        subText = '${pendingWithDate.length} deliver karna hai';
      } else {
        // Python: delivery_pending_days < 0 → ON SCHEDULE
        status = AlertStatus.safe;
        final formattedDate = DateFormat('dd MMM').format(nextDelivery);
        mainValue = 'ON SCHEDULE';
        subText = 'Next: $formattedDate ($diff days)';
      }
    }

    return AlertCardModel(
      id: 'deliveries',
      title: 'Deliveries',
      mainValue: mainValue,
      subText: subText,
      status: status,
      routeId: AppRoutes.deliveryManagementRoute,
    );
  }

  // ==========================================
  // HELPER — Indian Currency Format
  // ==========================================
  String _formatIndianCurrency(double amount) {
    if (amount == 0) return '₹0';
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  // ==========================================
  // LOADING STATE FACTORY
  // ==========================================
  static AlertRowModel _buildLoadingState() {
    return AlertRowModel(
      inventory: AlertCardModel.loading(
          'inventory', 'Inventory', AppRoutes.inventoryRoute),
      orders: AlertCardModel.loading(
          'orders', 'Orders', AppRoutes.pendingJobsRoute),
      collections: AlertCardModel.loading(
          'collections', 'Collections', AppRoutes.dueReportRoute),
      deliveries: AlertCardModel.loading(
          'deliveries', 'Deliveries', AppRoutes.deliveryManagementRoute),
    );
  }

  // ==========================================
  // RETRY
  // ==========================================
  void retry() => _refresh();

  // ==========================================
  // CLEANUP
  // ==========================================
  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}
