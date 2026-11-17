import 'package:intl/intl.dart';

import 'package:lotus_erp/models/live_rates/live_rates_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_price_unit.dart';
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
    final goldRates = _counterSellingRows(gold);
    final silverRates = _counterSellingRows(silver);
    if ([...goldRates, ...silverRates]
        .every((rate) => rate.perBaseUnit == '--')) {
      return LiveRatesModel.missing();
    }

    final updatedAt = gold.updatedAt.isAfter(silver.updatedAt)
        ? gold.updatedAt
        : silver.updatedAt;
    return LiveRatesModel(
      state: LiveRateState.available,
      goldRates: goldRates,
      silverRates: silverRates,
      oldGoldBuy: _format(gold.primaryBuyRatePer10g),
      oldSilverBuy: _format(silver.primaryBuyRatePer10g),
      rateDate: updatedAt,
      source: gold.marketSource == silver.marketSource
          ? gold.marketSource
          : 'Metal Rate Master',
    );
  }

  List<LiveMetalRate> _counterSellingRows(MetalRateProfile profile) {
    final unit = MetalRatePriceUnit.forMetal(profile.metal);
    return profile.purityPlans.map((plan) {
      final marketRate = profile.effectiveSellingRateFor(plan);
      return LiveMetalRate(
        purity: plan.label,
        perGram: _format(unit.toBillingRate(marketRate)),
        perBaseUnit: _format(unit.toMarket(marketRate)),
        description:
            profile.metal == MetalRateMetal.silver && plan.label == '700'
                ? 'Local Jewellery'
                : null,
      );
    }).toList(growable: false);
  }

  MetalRateProfile _find(
    List<MetalRateProfile> profiles,
    MetalRateMetal metal,
  ) =>
      profiles.firstWhere(
        (profile) => profile.metal == metal,
        orElse: () => MetalRateProfile.defaultFor(metal),
      );

  String _format(double value) {
    if (value <= 0) return '--';
    final formatter = NumberFormat.decimalPattern('en_IN')
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 2;
    return formatter.format(value);
  }
}
