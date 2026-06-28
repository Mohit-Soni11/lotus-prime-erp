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
    final enabledIds = saved == null
        ? fields
            .where((field) => field.defaultEnabled)
            .map((field) => field.id)
            .toSet()
        : saved.toSet();

    return ShopPrintInformationState(
      tenantId: tenantId,
      fields: fields,
      enabledFieldIds: enabledIds,
    );
  }

  Future<void> save(ShopPrintInformationState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyFor(state.tenantId),
      state.enabledFieldIds.toList()..sort(),
    );
  }

  String _keyFor(String tenantId) => '$_preferencePrefix.$tenantId.v1';
}
