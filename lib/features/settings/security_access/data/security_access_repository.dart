import 'package:lotus_erp/features/settings/security_access/domain/security_access_identity.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_session_manager.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_setup_repository.dart';
import 'package:lotus_erp/ui/auth/services/auth_service.dart';

class SecurityAccessRepository {
  SecurityAccessRepository({
    ShopSetupRepository? shopSetup,
    AuthService? authService,
  })  : _shopSetup = shopSetup ?? ShopSetupRepository(),
        _authService = authService ?? AuthService();

  final ShopSetupRepository _shopSetup;
  final AuthService _authService;

  Future<SecurityAccessIdentity> loadIdentity() async {
    final results = await Future.wait<Object?>([
      _loadShopProfile(),
      _authService.getUserDetails(),
    ]);
    final profile = results[0] as Map<String, dynamic>?;
    final account = results[1] as Map<String, dynamic>?;
    final basic = profile?['basic_info'] as Map<String, dynamic>?;
    final shopName = _firstText([
      basic?['brand_display_name'],
      basic?['display_name'],
      basic?['legal_name'],
      account?['name'],
      'Lotus ERP',
    ]);
    return SecurityAccessIdentity(
      shopName: shopName,
      logoPath: _nullableText(basic?['logo_path']),
      logoShape: _firstText([basic?['logo_shape'], 'circle']),
      lastPasswordChangedAt: DateTime.tryParse(
              (account?['lastPasswordChangedAt'] ?? '').toString())
          ?.toLocal(),
    );
  }

  Future<Map<String, dynamic>?> _loadShopProfile() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      return await _shopSetup.fetchExistingSetup(tenantId);
    } catch (_) {
      return null;
    }
  }

  static String _firstText(Iterable<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'Lotus ERP';
  }

  static String? _nullableText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
