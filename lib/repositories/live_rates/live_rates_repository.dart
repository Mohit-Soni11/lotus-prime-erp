import 'package:intl/intl.dart';

import 'package:lotus_erp/models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/repositories/setting/metal_rate/metal_rate_repository.dart';

/// Dashboard projection of the authoritative metal rate ledger.
class LiveRatesRepository {
  LiveRatesRepository({MetalRateRepository? repository})
      : _repository = repository ?? MetalRateRepository();

  final MetalRateRepository _repository;

  Stream<LiveRatesModel> watchRates() async* {
    yield LiveRatesModel.loading();
    try {
      yield* _repository.watchProfiles().map(_toDashboardModel);
    } catch (_) {
      yield LiveRatesModel.error();
    }
  }

  LiveRatesModel _toDashboardModel(List<MetalRateProfile> profiles) {
    final gold = _find(profiles, MetalRateMetal.gold);
    final silver = _find(profiles, MetalRateMetal.silver);
    final gold24 = _sellingRate(gold, '24K');
    final gold22 = _sellingRate(gold, '22K');
    final gold18 = _sellingRate(gold, '18K');
    final silver999 = _sellingRate(silver, '999');
    final silver925 = _sellingRate(silver, '925');
    if ([gold24, gold22, gold18, silver999, silver925]
        .every((rate) => rate <= 0)) {
      return LiveRatesModel.missing();
    }

    final updatedAt = gold.updatedAt.isAfter(silver.updatedAt)
        ? gold.updatedAt
        : silver.updatedAt;
    return LiveRatesModel(
      state: LiveRateState.available,
      gold24k: _format(gold24),
      gold22k: _format(gold22),
      gold18k: _format(gold18),
      silverRateKg: _format(silver999 * 100),
      silverJewellery: _format(silver925),
      silverIdols: _format(silver999),
      oldGold24kBuy: _format(_buyRate(gold, '24K')),
      oldGold22kBuy: _format(_buyRate(gold, '22K')),
      oldGold18kBuy: _format(_buyRate(gold, '18K')),
      oldSilverBuy: _format(_buyRate(silver, '999')),
      rateDate: updatedAt,
      source: gold.marketSource == silver.marketSource
          ? gold.marketSource
          : 'Metal Rate Master',
    );
  }

  MetalRateProfile _find(
    List<MetalRateProfile> profiles,
    MetalRateMetal metal,
  ) =>
      profiles.firstWhere(
        (profile) => profile.metal == metal,
        orElse: () => MetalRateProfile.defaultFor(metal),
      );

  double _sellingRate(MetalRateProfile profile, String label) {
    final plans = profile.purityPlans.where((plan) => plan.label == label);
    if (plans.isEmpty) return 0;
    final plan = plans.first;
    return plan.manualDisplayRatePer10g > 0
        ? plan.manualDisplayRatePer10g
        : profile.marketBaseRatePer10g * plan.purityFactor;
  }

  double _buyRate(MetalRateProfile profile, String label) {
    final plans = profile.purityPlans.where((plan) => plan.label == label);
    return plans.isEmpty ? 0 : plans.first.buyRatePer10g;
  }

  String _format(double value) => value <= 0
      ? '--'
      : NumberFormat.decimalPattern('en_IN').format(value.round());
}
