import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_session_manager.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_setup_repository.dart';

class ShopPrintInformationRepository {
  static const String _preferencePrefix =
      'billing_setup.shop_print_information.enabled_fields';

  final ShopSetupRepository _shopSetupRepository;

  ShopPrintInformationRepository({
    ShopSetupRepository? shopSetupRepository,
  }) : _shopSetupRepository = shopSetupRepository ?? ShopSetupRepository();

  Future<ShopPrintInformationState> load() async {
    final tenantId = await ShopSessionManager.getPermanentTenantId();
    final payload = await _shopSetupRepository.fetchExistingSetup(tenantId);
    final fields = ShopPrintInformationCatalog.fromPayload(payload);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyFor(tenantId));
    final enabledIds = _resolveEnabledIds(fields, saved);

    return ShopPrintInformationState(
      tenantId: tenantId,
      fields: fields,
      enabledFieldIds: enabledIds,
    );
  }

  Future<void> save(ShopPrintInformationState state) async {
    final prefs = await SharedPreferences.getInstance();
    final configuredIds = state.configuredFieldIds;
    final enabledIds = state.enabledFieldIds
        .where(configuredIds.contains)
        .toList(growable: false)
      ..sort();

    await prefs.setStringList(
      _keyFor(state.tenantId),
      enabledIds,
    );
  }

  Set<String> _resolveEnabledIds(
    List<ShopPrintField> fields,
    List<String>? saved,
  ) {
    final configuredIds = {
      for (final field in fields)
        if (field.isConfigured) field.id,
    };

    if (saved == null) {
      return fields
          .where((field) => field.defaultEnabled && field.isConfigured)
          .map((field) => field.id)
          .toSet();
    }

    return saved.where(configuredIds.contains).toSet();
  }

  String _keyFor(String tenantId) => '$_preferencePrefix.$tenantId.v1';
}
