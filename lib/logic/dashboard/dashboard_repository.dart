import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/dashboard/user_profile.dart';
import '../../models/dashboard/search_result.dart';
import '../../features/notifications/domain/notification_item.dart';
import '../../features/notifications/application/notification_center_controller.dart';
import '../../models/dashboard/customer_stats_model.dart';
import '../../constants/enums.dart';
import '../../features/dashboard/shop_identity/data/shop_identity_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class DashboardRepository {
  DashboardRepository({
    AppDatabase? db,
    ShopIdentityReader? shopIdentityReader,
  })  : _db = db ?? AppDatabase(),
        _shopIdentityReader = shopIdentityReader ?? ShopIdentityRepository();

  final AppDatabase _db;
  final ShopIdentityReader _shopIdentityReader;

  late final _notificationCenter = NotificationCenterController(_db);
  Stream<List<NotificationItem>> get notificationsStream =>
      _notificationCenter.stream;

  // ==========================================
  // 1. FETCH USER PROFILE (Short Info)
  // ==========================================
  Future<UserProfile> fetchUserProfile() async {
    try {
      final identity = await _shopIdentityReader.load();
      if (identity.isConfigured) {
        final ownerName = identity.ownerName;
        return UserProfile(
          name: ownerName.isEmpty ? identity.displayName : ownerName,
          role: UserRole.owner.name,
          isOnline: true,
        );
      }
      return const UserProfile(
        name: 'Setup Pending',
        role: 'staff',
        isOnline: false,
      );
    } catch (e) {
      AppLogger.error("Error fetching profile: $e");
      return const UserProfile(name: "Guest", role: "N/A", isOnline: false);
    }
  }

  // ==========================================
  // 3. LOAD NOTIFICATIONS
  // ==========================================
  Future<void> loadNotifications(String role) {
    return _notificationCenter.start(role);
  }

  // ==========================================
  // 4. MARK ALL READ
  // ==========================================
  Future<void> markAllRead(String role) async {
    await _notificationCenter.markAllRead();
  }

  Future<void> clearNotifications() => _notificationCenter.clearMessages();
  Future<void> markNotificationRead(NotificationItem item) =>
      _notificationCenter.markRead(item);

  // ==========================================
  // 5. FETCH CUSTOMER STATS
  // ==========================================
  Future<CustomerStatsModel> fetchCustomerStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Query: Count customers created today
      final count = await (_db.select(_db.customers)
            ..where((tbl) => tbl.createdAt.isBiggerOrEqualValue(startOfDay)))
          .get()
          .then((list) => list.length);

      // Logic: High Growth Rule (> 5)
      final bool isHighGrowth = count > 5;
      final String status = isHighGrowth ? "High Growth" : "Stable";

      final String formattedTime =
          "${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}";

      return CustomerStatsModel(
        count: count.toString().padLeft(2, '0'),
        status: status,
        isHighGrowth: isHighGrowth,
        syncTime: formattedTime,
      );
    } catch (e) {
      AppLogger.error("Error fetching customer stats: $e");
      return CustomerStatsModel.empty();
    }
  }

  // ==========================================
  // 6. SEARCH LOGIC
  // ==========================================
  Future<List<SearchResult>> searchUniversal(String query, SearchScope scope,
      {int limit = 10}) async {
    if (query.trim().isEmpty) return [];

    String term = query.toLowerCase();
    List<SearchResult> results = [];

    // 1. Customer Search
    if ([SearchScope.all, SearchScope.customer, SearchScope.mobile]
        .contains(scope)) {
      final customers = await (_db.select(_db.customers)
            ..where(
                (tbl) => tbl.name.contains(term) | tbl.mobile.contains(term))
            ..limit(5))
          .get();

      results.addAll(customers.map((c) => SearchResult(
          id: c.id.toString(),
          title: c.name,
          subtitle: c.mobile,
          type: "Customer")));
    }

    // 2. Invoice Search
    if ([SearchScope.all, SearchScope.invoice].contains(scope)) {
      final bills = await (_db.select(_db.bills)
            ..where((tbl) => tbl.billNo.contains(term))
            ..limit(5))
          .get();

      results.addAll(bills.map((b) => SearchResult(
          id: b.id.toString(),
          title: b.billNo,
          subtitle: "Amt: ₹${b.finalAmount.toStringAsFixed(2)}",
          type: "Invoice")));
    }

    // 3. Loan Search
    if ([SearchScope.all, SearchScope.loan].contains(scope)) {
      final loans = await (_db.select(_db.loans)
            ..where((tbl) =>
                tbl.loanNo.contains(term) | tbl.itemDesc.contains(term))
            ..limit(5))
          .get();

      results.addAll(loans.map((l) => SearchResult(
          id: l.id.toString(),
          title: l.loanNo,
          subtitle: "${l.itemDesc} (${l.grossWeight}g)",
          type: "Loan")));
    }

    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  void dispose() {
    _notificationCenter.dispose();
  }
}
