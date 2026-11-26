import 'package:lotus_erp/database/local_database/shop_database_helper.dart';
import 'package:lotus_erp/features/dashboard/shop_identity/domain/shop_identity.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_session_manager.dart';

abstract interface class ShopIdentityReader {
  Future<ShopIdentity> load();
}

class ShopIdentityRepository implements ShopIdentityReader {
  ShopIdentityRepository({
    Future<Map<String, dynamic>?> Function()? payloadLoader,
  }) : _payloadLoader = payloadLoader ?? _loadPersistedPayload;

  final Future<Map<String, dynamic>?> Function() _payloadLoader;

  @override
  Future<ShopIdentity> load() async {
    final payload = await _payloadLoader();
    if (payload == null) return const ShopIdentity.notConfigured();

    final basicInfo = _section(payload, 'basic_info');
    final address = _section(payload, 'address');
    final tax = _section(payload, 'tax_compliance');
    final branding = _section(payload, 'branding_social');

    final displayName = _firstValue([
      basicInfo['brand_display_name'],
      basicInfo['display_name'],
      basicInfo['legal_name'],
    ]);
    if (displayName.isEmpty) return const ShopIdentity.notConfigured();

    return ShopIdentity(
      status: ShopIdentityStatus.configured,
      displayName: displayName,
      ownerName: _text(basicInfo['owner_name']),
      city: _text(address['city']),
      state: _text(address['state']),
      mobile: _text(basicInfo['shop_phone']),
      email: _text(basicInfo['business_email']),
      website: _text(branding['website']),
      gstin: _text(tax['gstin']),
      bisLicense: _text(tax['bis_license_no']),
      logoPath: _nullableText(basicInfo['logo_path']),
      logoShape: _logoShape(basicInfo['logo_shape']),
    );
  }

  static Future<Map<String, dynamic>?> _loadPersistedPayload() async {
    final tenantId = await ShopSessionManager.getPermanentTenantId();
    return ShopDatabaseHelper().getMasterPayload(tenantId);
  }

  static Map<String, dynamic> _section(
    Map<String, dynamic> payload,
    String key,
  ) {
    final rawValue = payload[key];
    if (rawValue is! Map) return const <String, dynamic>{};
    return rawValue.map(
      (mapKey, value) => MapEntry(mapKey.toString(), value),
    );
  }

  static String _firstValue(Iterable<Object?> values) {
    for (final value in values) {
      final text = _text(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static String? _nullableText(Object? value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  static String _logoShape(Object? value) =>
      _text(value).toLowerCase() == 'square' ? 'square' : 'circle';
}
