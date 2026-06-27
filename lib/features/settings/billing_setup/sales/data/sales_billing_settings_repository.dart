import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../../../../repositories/setting/billing_setup/sales_billing_repo.dart';

class SalesBillingSettingsRepository {
  final SalesBillingRepo _repo;

  SalesBillingSettingsRepository({SalesBillingRepo? repo})
      : _repo = repo ?? SalesBillingRepo();

  Future<Map<String, SalesBillingModel>> fetchAll() async {
    final settings = <String, SalesBillingModel>{};
    for (final metal in BillingMetal.all) {
      settings[metal] = await _repo.fetchForMetal(metal);
    }
    return Map.unmodifiable(settings);
  }

  Future<bool> save(SalesBillingModel model) {
    return _repo.saveForMetal(model);
  }
}
