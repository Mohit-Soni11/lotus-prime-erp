import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../../database/db/app_database.dart';
import '../../models/dashboard/user_profile.dart';
import '../../models/dashboard/shop_profile_model.dart'; // Import for Shop Card
import '../../models/dashboard/search_result.dart';
import '../../models/dashboard/notification_item.dart';
import '../../models/dashboard/customer_stats_model.dart';
import '../../constants/enums.dart';
import '../../database/local_database/shop_database_helper.dart';
import '../../repositories/setting/shop_setup/shop_session_manager.dart';

class DashboardRepository {
  DashboardRepository({
    AppDatabase? db,
    Future<Map<String, dynamic>?> Function()? shopSetupLoader,
  })  : _db = db ?? AppDatabase(),
        _shopSetupLoader = shopSetupLoader ?? _loadShopSetup;

  final AppDatabase _db;
  final Future<Map<String, dynamic>?> Function() _shopSetupLoader;

  // Stream Controller for Notifications
  final _notificationController =
      StreamController<List<NotificationItem>>.broadcast();

  Stream<List<NotificationItem>> get notificationsStream =>
      _notificationController.stream;

  // ==========================================
  // 1. FETCH USER PROFILE (Short Info)
  // ==========================================
  Future<UserProfile> fetchUserProfile() async {
    try {
      // ✅ FIX: Map karte waqt koi column null ho to crash na ho
      final rows = await _db.customSelect(
        'SELECT id, shop_name, owner_name FROM shop_profiles LIMIT 1',
        readsFrom: {_db.shopProfiles},
      ).get();

      if (rows.isNotEmpty) {
        final row = rows.first;
        final ownerName = row.read<String?>('owner_name') ?? 'Admin';
        return UserProfile(
          name: ownerName.isEmpty ? 'Admin' : ownerName,
          role: UserRole.owner.name,
          isOnline: true,
        );
      } else {
        return const UserProfile(
          name: 'Setup Pending',
          role: 'staff',
          isOnline: false,
        );
      }
    } catch (e) {
      debugPrint("❌ Error fetching profile: $e");
      return const UserProfile(name: "Guest", role: "N/A", isOnline: false);
    }
  }

  // ==========================================
  // 🔥 2. FETCH FULL SHOP DETAILS (ADDED & FIXED)
  // ==========================================
  // Ye method tumhare code me missing tha, isliye error aa raha tha.
  Future<ShopProfileModel> fetchFullShopDetails() async {
    try {
      // ✅ FIX: customSelect use karo taaki openingCashBalance NULL crash na kare
      final rows = await _db.customSelect(
        '''SELECT id, shop_name, legal_name, owner_name, contact_number,
                  email, website, city, state, gstin, bis_license, huid_no,
                  logo_path, logo_shape, show_mobile, show_email, show_gst
           FROM shop_profiles LIMIT 1''',
        readsFrom: {_db.shopProfiles},
      ).get();

      if (rows.isNotEmpty) {
        final row = rows.first;
        final driftLogoPath = row.read<String?>('logo_path')?.trim() ?? '';
        final driftLogoShape = row.read<String?>('logo_shape')?.trim() ?? '';
        final savedIdentity = driftLogoPath.isEmpty
            ? await _fetchSavedIdentity()
            : (
                logoPath: driftLogoPath,
                logoShape: _normalizeLogoShape(driftLogoShape),
              );

        return ShopProfileModel(
          displayName: row.read<String?>('shop_name') ?? 'My Shop',
          ownerName: row.read<String?>('owner_name') ?? '--',
          city: row.read<String?>('city') ?? '',
          state: row.read<String?>('state') ?? '',
          mobile: row.read<String?>('contact_number') ?? '',
          email: row.read<String?>('email') ?? '',
          website: row.read<String?>('website') ?? '',
          gstin: row.read<String?>('gstin') ?? '',
          bisLicense: row.read<String?>('bis_license') ?? '',
          huidNo: row.read<String?>('huid_no') ?? '',
          logoPath: savedIdentity.logoPath,
          logoShape: savedIdentity.logoShape,
          showMobile: (row.read<int?>('show_mobile') ?? 1) == 1,
          showEmail: (row.read<int?>('show_email') ?? 1) == 1,
          showGst: (row.read<int?>('show_gst') ?? 1) == 1,
        );
      }
      return ShopProfileModel.empty();
    } catch (e) {
      debugPrint("❌ Error fetching shop details: $e");
      throw Exception("Database Error");
    }
  }

  // ==========================================
  // 3. LOAD NOTIFICATIONS
  // ==========================================
  void loadNotifications(String role) async {
    try {
      final query = _db.select(_db.notifications)
        ..where((tbl) => tbl.role.equals(role) | tbl.role.equals('all'))
        ..orderBy(
            [(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]);

      final dbList = await query.get();

      final uiList = dbList
          .map((row) => NotificationItem(
                id: row.id,
                type: row.type,
                title: row.title,
                desc: row.desc,
                targetRole: row.role,
                isRead: row.isRead,
              ))
          .toList();

      _notificationController.add(uiList);
    } catch (e) {
      debugPrint("❌ Error loading notifications: $e");
      _notificationController.add([]);
    }
  }

  // ==========================================
  // 4. MARK ALL READ
  // ==========================================
  Future<void> markAllRead(String role) async {
    await (_db.update(_db.notifications)
          ..where((tbl) => tbl.role.equals(role) | tbl.role.equals('all')))
        .write(const NotificationsCompanion(isRead: Value(true)));

    loadNotifications(role);
  }

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
      final String status = isHighGrowth ? "High Growth 🚀" : "Stable";

      final String formattedTime =
          "${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}";

      return CustomerStatsModel(
        count: count.toString().padLeft(2, '0'),
        status: status,
        isHighGrowth: isHighGrowth,
        syncTime: formattedTime,
      );
    } catch (e) {
      debugPrint("❌ Error fetching customer stats: $e");
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
    _notificationController.close();
  }

  Future<({String? logoPath, String logoShape})> _fetchSavedIdentity() async {
    try {
      final payload = await _shopSetupLoader();
      final rawBasicInfo = payload?['basic_info'];
      final basicInfo = rawBasicInfo is Map
          ? rawBasicInfo.map(
              (key, value) => MapEntry(key.toString(), value),
            )
          : const <String, dynamic>{};
      final logoPath = basicInfo['logo_path']?.toString().trim() ?? '';
      return (
        logoPath: logoPath.isEmpty ? null : logoPath,
        logoShape: _normalizeLogoShape(
          basicInfo['logo_shape']?.toString() ?? '',
        ),
      );
    } catch (_) {
      return (logoPath: null, logoShape: 'circle');
    }
  }

  static Future<Map<String, dynamic>?> _loadShopSetup() async {
    final tenantId = await ShopSessionManager.getPermanentTenantId();
    return ShopDatabaseHelper().getMasterPayload(tenantId);
  }

  static String _normalizeLogoShape(String value) {
    return value.trim().toLowerCase() == 'square' ? 'square' : 'circle';
  }
}
