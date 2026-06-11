import '../../database/db/app_database.dart';
import '../../database/local_database/shop_database_helper.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../setting/shop_setup/shop_session_manager.dart';

class GirviInvoiceBrandingRepository {
  GirviInvoiceBrandingRepository({
    AppDatabase? db,
    Future<Map<String, dynamic>?> Function()? shopSetupLoader,
  })  : _db = db ?? AppDatabase(),
        _shopSetupLoader = shopSetupLoader ?? _loadShopSetup;

  final AppDatabase _db;
  final Future<Map<String, dynamic>?> Function() _shopSetupLoader;

  Future<GirviInvoiceBranding> fetch() async {
    try {
      final payload = await _shopSetupLoader();
      if (payload != null) {
        final branding = GirviInvoiceBranding.fromShopSetup(payload);
        if (branding.shopName != GirviInvoiceBranding.fallback.shopName) {
          return branding;
        }
      }
    } catch (_) {
      // Drift profile below remains available for older shop setups.
    }

    try {
      final profile =
          await (_db.select(_db.shopProfiles)..limit(1)).getSingleOrNull();
      if (profile == null) return GirviInvoiceBranding.fallback;

      final address = [
        profile.address,
        profile.city,
        profile.state,
        profile.pincode,
      ]
          .map((value) => value?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .join(', ');
      final mobile = (profile.contactNumber?.trim().isNotEmpty ?? false)
          ? profile.contactNumber!.trim()
          : profile.ownerContact?.trim() ?? '';

      return GirviInvoiceBranding(
        shopName: profile.shopName.trim().isEmpty
            ? GirviInvoiceBranding.fallback.shopName
            : profile.shopName.trim(),
        shopAddress: address.isEmpty
            ? GirviInvoiceBranding.fallback.shopAddress
            : address,
        shopMobile: mobile,
        shopGstin: profile.gstin?.trim() ?? '',
        logoPath: profile.logoPath?.trim().isEmpty ?? true
            ? null
            : profile.logoPath!.trim(),
        logoShape: profile.logoShape,
      );
    } catch (_) {
      return GirviInvoiceBranding.fallback;
    }
  }

  static Future<Map<String, dynamic>?> _loadShopSetup() async {
    final tenantId = await ShopSessionManager.getPermanentTenantId();
    return ShopDatabaseHelper().getMasterPayload(tenantId);
  }
}
