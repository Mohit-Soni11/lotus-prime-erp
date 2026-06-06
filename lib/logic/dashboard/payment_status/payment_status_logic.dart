// =============================================================================
// FILE        : payment_status_logic.dart
// MODULE      : Dashboard / Payment Status
// LAYER       : Logic (Business Logic)
// DESCRIPTION : Payment Status Card ka poora data management.
//
//               DB CONNECTIONS:
//               • Bills table     → payment data (billNo, amounts, date, status)
//               • Customers table → customer name, mobile, id (for navigation)
//
//               LIVE WATCHING:
//               Bills table watch karta hai — koi bhi change hone par
//               auto-refresh. ChangeNotifier pattern (ShopCardLogic jaisa).
//
//               LOGIC:
//               • paidAmount = bills.paidAmount (new column from v5)
//               • dueAmount  = finalAmount - paidAmount
//               • status     = PAID / PARTIAL / UNPAID (computed)
//               • Summary    = counts + sum of amounts
//               • Filter     = ALL / DUE / PAID tabs
//               • Sort       = Latest bills pehle
//               • Limit      = 10 bills max (performance)
//
//               NAVIGATION:
//               • Customer name tap → customerProfileRoute
// =============================================================================

import 'dart:async';
//import 'package:drift/drift.dart' show OrderingTerm, OrderingMode;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import '../../../database/db/app_database.dart';
import '../../../models/dashboard/payment_bill_item.dart';
import '../../../models/dashboard/payment_status_model.dart';

class PaymentStatusLogic extends ChangeNotifier {
  // ── Dependencies ───────────────────────────────────────────────────────────
  final AppDatabase _db;
  PaymentStatusLogic({AppDatabase? db}) : _db = db ?? AppDatabase() {
    _startLiveWatch();
  }

  // ── State ──────────────────────────────────────────────────────────────────
  PaymentStatusModel _data = PaymentStatusModel.loading();
  bool _isExpanded = false; // Show more / show less
  bool _hasError = false;

  PaymentStatusModel get data => _data;
  bool get isExpanded => _isExpanded;
  bool get hasError => _hasError;
  bool get isLoading => _data.isLoading;

  // Max bills dikhane ki limit
  static const int _kVisibleLimit = 3; // Collapsed mein
  static const int _kExpandedLimit = 10; // Expanded mein
  static const int _kFetchLimit = 10; // DB se kitne lao

  // Kitne bills dikhenge currently
  int get visibleCount => _isExpanded ? _kExpandedLimit : _kVisibleLimit;

  // ── DB Subscription ────────────────────────────────────────────────────────
  StreamSubscription? _billsSub;

  // ==========================================
  // LIVE WATCH — Bills table change hone par auto-update
  // ==========================================
  void _startLiveWatch() {
    // Recent bills watch — latest pehle, limit se zyada mat lao
    final query = _db.select(_db.bills)
      ..where((t) => t.status.equals('ACTIVE'))
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.desc(t.billDate),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(_kFetchLimit);

    _billsSub = query.watch().listen(
      (bills) => _processBills(bills),
      onError: (_) {
        _hasError = true;
        notifyListeners();
      },
    );
  }

  // ==========================================
  // PROCESS — Bills se PaymentBillItem list banao
  // ==========================================
  Future<void> _processBills(List<Bill> bills) async {
    try {
      final List<PaymentBillItem> items = [];

      for (final bill in bills) {
        // Customer data fetch karo (agar customerId available hai)
        String customerName = bill.customerName ?? 'Walk-in Customer';
        int? customerId = bill.customerId;

        if (customerId != null) {
          final customer = await (_db.select(_db.customers)
                ..where((t) => t.id.equals(customerId)))
              .getSingleOrNull();
          if (customer != null) {
            customerName = customer.name;
          }
        }

        // Amounts compute karo
        final double total = bill.finalAmount;
        final double paid = bill.paidAmount;
        final double due = _currentDue(bill);
        final PaymentStatus status = _statusFromDue(paid: paid, due: due);

        items.add(PaymentBillItem(
          billId: bill.id,
          billNo: bill.billNo,
          customerName: customerName,
          customerInitials: PaymentBillItem.extractInitials(customerName),
          customerId: customerId,
          mobile: bill.mobile ?? '',
          totalAmount: total,
          paidAmount: paid,
          dueAmount: due,
          billDate: bill.billDate,
          status: status,
        ));
      }

      // Summary compute karo
      final summary = _computeSummary(items);

      _data = PaymentStatusModel(
        summary: summary,
        bills: items,
        activeTab: _data.activeTab, // active tab same rakho
      );
      _hasError = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ PaymentStatusLogic error: $e');
      _hasError = true;
      notifyListeners();
    }
  }

  // ==========================================
  // SUMMARY COMPUTE
  // ==========================================
  PaymentSummary _computeSummary(List<PaymentBillItem> items) {
    double collected = 0;
    double pending = 0;
    int paidCnt = 0, partialCnt = 0, unpaidCnt = 0;

    for (final item in items) {
      collected += item.paidAmount;
      pending += item.dueAmount;
      switch (item.status) {
        case PaymentStatus.paid:
          paidCnt++;
          break;
        case PaymentStatus.partial:
          partialCnt++;
          break;
        case PaymentStatus.unpaid:
          unpaidCnt++;
          break;
      }
    }

    return PaymentSummary(
      totalBills: items.length,
      totalCollected: collected,
      totalPending: pending,
      paidCount: paidCnt,
      partialCount: partialCnt,
      unpaidCount: unpaidCnt,
    );
  }

  double _currentDue(Bill bill) {
    final computed = bill.finalAmount - bill.paidAmount;
    final due = bill.dueAmount > 0.5 ? bill.dueAmount : computed;
    return due.clamp(0.0, double.infinity).toDouble();
  }

  PaymentStatus _statusFromDue({
    required double paid,
    required double due,
  }) {
    if (due <= 0.5) return PaymentStatus.paid;
    if (paid > 0.5) return PaymentStatus.partial;
    return PaymentStatus.unpaid;
  }

  // ==========================================
  // INTERACTIONS
  // ==========================================

  /// Filter tab change karo
  void setTab(PaymentFilterTab tab) {
    _data = _data.withTab(tab);
    notifyListeners();
  }

  /// Show More / Show Less toggle
  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  /// Retry on error
  void retry() => _startLiveWatch();

  // ==========================================
  // FORMATTERS — Indian currency style
  // ==========================================
  static String formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  static String formatAmountFull(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(billDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return DateFormat('dd MMM').format(date);
  }

  // ==========================================
  // CLEANUP
  // ==========================================
  @override
  void dispose() {
    _billsSub?.cancel();
    super.dispose();
  }
}
