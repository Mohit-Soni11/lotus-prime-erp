import '../../../../../../models/setting/billing_setup/booking_advance_billing_model.dart';
import '../../../../../../repositories/setting/billing_setup/booking_advance_billing_repo.dart';

class BookingAdvanceBillingSettingsRepository {
  final BookingAdvanceBillingRepo _repo;

  BookingAdvanceBillingSettingsRepository({
    BookingAdvanceBillingRepo? repo,
  }) : _repo = repo ?? BookingAdvanceBillingRepo();

  Future<BookingAdvanceBillingModel> fetch() {
    return _repo.fetch();
  }

  Future<bool> save(BookingAdvanceBillingModel model) {
    return _repo.save(model);
  }
}
