import 'package:lotus_erp/models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/repositories/live_rates/live_rates_repository.dart';

class LiveRatesLogic {
  LiveRatesLogic({LiveRatesRepository? repository})
      : _repository = repository ?? LiveRatesRepository();

  final LiveRatesRepository _repository;

  Stream<LiveRatesModel> get ratesStream => _repository.watchRates();
  LiveRatesModel get initialData => LiveRatesModel.loading();
}
