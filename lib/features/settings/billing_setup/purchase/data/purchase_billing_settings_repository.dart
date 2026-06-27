import '../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../../../../repositories/setting/billing_setup/purchase_billing_repo.dart';

class PurchaseBillingSettingsRepository {
  final PurchaseBillingRepo _repo;

  PurchaseBillingSettingsRepository({PurchaseBillingRepo? repo})
      : _repo = repo ?? PurchaseBillingRepo();

  Future<Map<String, PurchaseBillingModel>> fetchAll() async {
    final settings = <String, PurchaseBillingModel>{};
    for (final metal in BillingMetal.all) {
      settings[metal] = await _repo.fetchForMetal(metal);
    }
    return Map.unmodifiable(settings);
  }

  Future<bool> save(PurchaseBillingModel model) {
    return _repo.saveForMetal(model);
  }
}
