// -----------------------------------------------------------------------------
// FILE: customer_list_repository.dart
// MODULE: Customer → Customer List
// DESCRIPTION: Data access layer. Fetches from Drift DB and maps to UI models.
// -----------------------------------------------------------------------------
 
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/customer/customer_list/customer_list_ui_model.dart';
import '../../models/customer/customer_enums/customer_list_enums.dart';
 
class CustomerListRepository {
  final AppDatabase _db;
 
  CustomerListRepository({AppDatabase? db}) : _db = db ?? AppDatabase();
 
  // ──────────────────────────────────────────────────────────────────────────
  // 1. LIVE STREAM: All Customers (watches DB changes in real-time)
  // ──────────────────────────────────────────────────────────────────────────
  Stream<List<CustomerListItemModel>> watchAllCustomers() {
    return _db.select(_db.customers).watch().asyncMap((rows) async {
      // For each customer, also fetch their bill count
      List<CustomerListItemModel> result = [];
      for (final row in rows) {
        final billCount = await _getBillCount(row.id);
        result.add(_mapToUiModel(row, billCount));
      }
      return result;
    });
  }
 
  // ──────────────────────────────────────────────────────────────────────────
  // 2. SEARCH: Filter by name or mobile
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<CustomerListItemModel>> searchCustomers(String query) async {
    try {
      final term = query.toLowerCase().trim();
      if (term.isEmpty) return getAllCustomers();
 
      final rows = await (_db.select(_db.customers)
        ..where((tbl) => tbl.name.contains(term) | tbl.mobile.contains(term))
        ..orderBy([(t) => OrderingTerm(expression: t.name)])
      ).get();
 
      List<CustomerListItemModel> result = [];
      for (final row in rows) {
        final billCount = await _getBillCount(row.id);
        result.add(_mapToUiModel(row, billCount));
      }
      return result;
    } catch (e) {
      debugPrint("❌ Search Error: $e");
      return [];
    }
  }
 
  // ──────────────────────────────────────────────────────────────────────────
  // 3. FETCH ALL with optional filter
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<CustomerListItemModel>> getAllCustomers({
    CustomerFilter filter = CustomerFilter.all,
    CustomerSort sort = CustomerSort.newest,
  }) async {
    try {
      final query = _db.select(_db.customers);
 
      // Apply filter
      switch (filter) {
        case CustomerFilter.vip:
          query.where((tbl) => tbl.type.equals('VIP'));
          break;
        case CustomerFilter.regular:
          query.where((tbl) => tbl.type.equals('Regular'));
          break;
        case CustomerFilter.today:
          final today = DateTime.now();
          final start = DateTime(today.year, today.month, today.day);
          query.where((tbl) => tbl.createdAt.isBiggerOrEqualValue(start));
          break;
        case CustomerFilter.all:
          break;
      }
 
      // Apply sort
      switch (sort) {
        case CustomerSort.nameAsc:
          query.orderBy([(t) => OrderingTerm(expression: t.name)]);
          break;
        case CustomerSort.nameDesc:
          query.orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.desc)]);
          break;
        case CustomerSort.newest:
          query.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
          break;
        case CustomerSort.oldest:
          query.orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
          break;
        case CustomerSort.mostBills:
          // Will sort after fetching bill counts
          break;
      }
 
      final rows = await query.get();
      List<CustomerListItemModel> result = [];
      for (final row in rows) {
        final billCount = await _getBillCount(row.id);
        result.add(_mapToUiModel(row, billCount));
      }
 
      // Post-sort for mostBills
      if (sort == CustomerSort.mostBills) {
        result.sort((a, b) => b.billCount.compareTo(a.billCount));
      }
 
      return result;
    } catch (e) {
      debugPrint("❌ Fetch Error: $e");
      return [];
    }
  }
 
  // ──────────────────────────────────────────────────────────────────────────
  // 4. STATS
  // ──────────────────────────────────────────────────────────────────────────
  Future<CustomerListStatsModel> fetchStats() async {
    try {
      final all = await _db.select(_db.customers).get();
      final total = all.length;
      final vip = all.where((c) => c.type == 'VIP').length;
 
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final todayNew = all.where((c) => c.createdAt.isAfter(start)).length;
 
      return CustomerListStatsModel(
        totalCount: total,
        todayCount: todayNew,
        vipCount: vip,
      );
    } catch (e) {
      debugPrint("❌ Stats Error: $e");
      return CustomerListStatsModel.empty();
    }
  }
 
  // ──────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ──────────────────────────────────────────────────────────────────────────
  Future<int> _getBillCount(int customerId) async {
    try {
      final countExpr = _db.bills.id.count();
      final query = _db.selectOnly(_db.bills)
        ..addColumns([countExpr])
        ..where(_db.bills.customerId.equals(customerId));
      final result = await query.getSingleOrNull();
      return result?.read(countExpr) ?? 0;
    } catch (_) {
      return 0;
    }
  }
 
  CustomerListItemModel _mapToUiModel(dynamic row, int billCount) {
    final name = row.name as String? ?? "Unknown";
    return CustomerListItemModel(
      id: row.id as int,
      name: name,
      mobile: row.mobile as String? ?? "",
      city: row.city as String? ?? "",
      type: CustomerType.fromString(row.type as String?),
      billCount: billCount,
      createdAt: row.createdAt as DateTime? ?? DateTime.now(),
      initials: CustomerListItemModel.buildInitials(name),
    );
  }
}