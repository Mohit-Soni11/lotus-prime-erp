import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';
import 'package:lotus_erp/repositories/setting/billing_setup/girvi_billing_repo.dart';

class GirviBillingSettingsRepository {
  final GirviBillingRepo _repo;

  GirviBillingSettingsRepository({GirviBillingRepo? repo})
      : _repo = repo ?? GirviBillingRepo();

  Future<GirviBillingModel> fetch() {
    return _repo.fetch();
  }

  Future<bool> save(GirviBillingModel model) {
    return _repo.save(model);
  }
}
