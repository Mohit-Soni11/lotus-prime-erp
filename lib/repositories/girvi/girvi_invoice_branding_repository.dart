import '../../database/db/app_database.dart';
import '../../database/local_database/shop_database_helper.dart';
import '../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../models/girvi/girvi_invoice_branding.dart';
import '../setting/shop_setup/shop_session_manager.dart';

class GirviInvoiceBrandingRepository {
  GirviInvoiceBrandingRepository({
    AppDatabase? db,
    Future<Map<String, dynamic>?> Function()? shopSetupLoader,
    Future<ShopPrintDocumentProfile> Function()? printProfileLoader,
  })  : _db = db ?? AppDatabase(),
        _shopSetupLoader = shopSetupLoader ?? _loadShopSetup,
        _printProfileLoader = printProfileLoader ??
            (() => ShopPrintInformationRepository().loadDocumentProfile());

  final AppDatabase _db;
  final Future<Map<String, dynamic>?> Function() _shopSetupLoader;
  final Future<ShopPrintDocumentProfile> Function() _printProfileLoader;

  Future<GirviInvoiceBranding> fetch() async {
    try {
      final payload = await _shopSetupLoader();
      if (payload != null) {
        final printProfile = await _loadPrintProfileSafely();
        final branding = GirviInvoiceBranding.fromShopSetup(
          payload,
          printProfile: printProfile,
        );
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
      final whatsapp = profile.whatsappNumber?.trim() ?? '';
      final alternateMobile =
          _phoneDigits(whatsapp) == _phoneDigits(mobile) ? '' : whatsapp;

      return GirviInvoiceBranding(
        shopName: profile.shopName.trim().isEmpty
            ? GirviInvoiceBranding.fallback.shopName
            : profile.shopName.trim(),
        shopAddress: address.isEmpty
            ? GirviInvoiceBranding.fallback.shopAddress
            : address,
        shopMobile: mobile,
        shopAlternateMobile: alternateMobile,
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

  Future<ShopPrintDocumentProfile> _loadPrintProfileSafely() async {
    try {
      return await _printProfileLoader();
    } catch (_) {
      return ShopPrintDocumentProfile.empty;
    }
  }

  static Future<Map<String, dynamic>?> _loadShopSetup() async {
    final tenantId = await ShopSessionManager.getPermanentTenantId();
    return ShopDatabaseHelper().getMasterPayload(tenantId);
  }

  static String _phoneDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}
