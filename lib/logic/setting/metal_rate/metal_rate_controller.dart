// =============================================================================
// FILE        : lib/logic/setting/metal_rate/metal_rate_controller.dart
// MODULE      : Metal Rate Setting
// LAYER       : Logic / Controller
// DESCRIPTION : ChangeNotifier controller for manual metal rate master screens.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../repositories/setting/metal_rate/metal_rate_repository.dart';

enum MetalRateLoadState { idle, loading, loaded, saving, error }

class MetalRateController extends ChangeNotifier {
  final MetalRateRepository _repo;

  MetalRateController({MetalRateRepository? repo})
      : _repo = repo ?? MetalRateRepository() {
    load();
  }

  MetalRateLoadState _state = MetalRateLoadState.idle;
  String? _errorMessage;
  final Map<MetalRateMetal, MetalRateProfile> _profiles = {};
  final Map<MetalRateMetal, List<MetalRateHistoryEntry>> _history = {};

  MetalRateLoadState get state => _state;
  String? get errorMessage => _errorMessage;

  List<MetalRateProfile> get profiles =>
      MetalRateMetal.values.map(profileFor).toList(growable: false);

  List<MetalRateHistoryEntry> historyFor(MetalRateMetal metal) =>
      _history[metal] ?? const [];

  DateTime get _historyStart => DateTime(DateTime.now().year);

  MetalRateProfile profileFor(MetalRateMetal metal) {
    return _profiles[metal] ?? MetalRateProfile.defaultFor(metal);
  }

  Future<void> load() async {
    _state = MetalRateLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repo.loadProfiles();
      _profiles
        ..clear()
        ..addEntries(loaded.map((profile) => MapEntry(profile.metal, profile)));

      for (final profile in loaded) {
        _history[profile.metal] =
            await _repo.loadHistory(profile.metal, from: _historyStart);
      }

      _state = MetalRateLoadState.loaded;
    } catch (error) {
      _errorMessage = error.toString();
      _state = MetalRateLoadState.error;
    }

    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> saveProfile(MetalRateProfile profile) async {
    _state = MetalRateLoadState.saving;
    _errorMessage = null;
    _profiles[profile.metal] = profile;
    notifyListeners();

    try {
      await _repo.saveProfile(profile);
      final saved = await _repo.loadProfile(profile.metal);
      _profiles[profile.metal] = saved;
      _history[profile.metal] =
          await _repo.loadHistory(profile.metal, from: _historyStart);
      _state = MetalRateLoadState.loaded;
    } catch (error) {
      _errorMessage = error.toString();
      _state = MetalRateLoadState.error;
    }

    notifyListeners();
  }

  Future<void> resetProfile(MetalRateMetal metal) async {
    _state = MetalRateLoadState.saving;
    notifyListeners();

    try {
      await _repo.resetProfile(metal);
      _profiles[metal] = await _repo.loadProfile(metal);
      _history[metal] = await _repo.loadHistory(metal, from: _historyStart);
      _state = MetalRateLoadState.loaded;
    } catch (error) {
      _errorMessage = error.toString();
      _state = MetalRateLoadState.error;
    }

    notifyListeners();
  }

  void stageProfile(MetalRateProfile profile) {
    _profiles[profile.metal] = profile;
    notifyListeners();
  }

  void updateReferenceRate(MetalRateMetal metal, double value) {
    final profile = profileFor(metal);
    final safeValue = value.clamp(0, 9999999).toDouble();
    stageProfile(
      profile.copyWith(
        mcxRatePer10g: safeValue,
        marketSource: 'Manual Rate Master',
      ),
    );
  }

  void updatePhysicalRate(MetalRateMetal metal, double value) {
    final profile = profileFor(metal);
    final safeValue = value.clamp(0, 9999999).toDouble();
    final next = profile.copyWith(
      physicalMarketRatePer10g: safeValue,
      marketSource: 'Manual Rate Master',
    );
    stageProfile(
      _syncMarketFollowerRates(
        previous: profile,
        next: next.copyWith(marketRatePer10g: next.marketBaseRatePer10g),
      ),
    );
  }

  void updateMarketInputs({
    required MetalRateMetal metal,
    double? mcxRate,
    double? physicalRate,
  }) {
    final profile = profileFor(metal);
    final next = profile.copyWith(
      mcxRatePer10g: mcxRate?.clamp(0, 9999999).toDouble(),
      physicalMarketRatePer10g: physicalRate?.clamp(0, 9999999).toDouble(),
      marketSource: 'Manual Rate Master',
    );
    final updated = next.copyWith(marketRatePer10g: next.marketBaseRatePer10g);
    stageProfile(
      physicalRate == null
          ? updated
          : _syncMarketFollowerRates(previous: profile, next: updated),
    );
  }

  void updateShopRate({
    required MetalRateMetal metal,
    required int index,
    required double value,
  }) {
    _updatePlan(
      metal: metal,
      index: index,
      patch: (plan) => plan.copyWith(
        manualDisplayRatePer10g: value.clamp(0, 9999999).toDouble(),
      ),
    );
  }

  void updateOldMetalPurchaseRate(MetalRateMetal metal, double value) {
    stageProfile(
      profileFor(metal).copyWith(
        oldMetalPurchaseRatePer10g: value.clamp(0, 9999999).toDouble(),
        marketSource: 'Manual Rate Master',
      ),
    );
  }

  void _updatePlan({
    required MetalRateMetal metal,
    required int index,
    required MetalRatePurityPlan Function(MetalRatePurityPlan plan) patch,
  }) {
    final profile = profileFor(metal);
    if (index < 0 || index >= profile.purityPlans.length) {
      return;
    }

    final plans = List<MetalRatePurityPlan>.from(profile.purityPlans);
    plans[index] = patch(plans[index]);
    stageProfile(
      profile.copyWith(
        marketSource: 'Manual Rate Master',
        purityPlans: plans,
      ),
    );
  }
}

MetalRateProfile _syncMarketFollowerRates({
  required MetalRateProfile previous,
  required MetalRateProfile next,
}) {
  if (next.metal == MetalRateMetal.silver) {
    // Silver category counter rates are independent of the local kg base.
    // A zero override keeps the live market-parity calculation active.
    return next;
  }
  final oldBase = previous.marketBaseRatePer10g;
  final newBase = next.marketBaseRatePer10g;
  if (newBase <= 0 || next.purityPlans.isEmpty) {
    return next;
  }

  final plans = <MetalRatePurityPlan>[];
  for (var index = 0; index < next.purityPlans.length; index++) {
    final plan = next.purityPlans[index];
    final oldPlan = index < previous.purityPlans.length
        ? previous.purityPlans[index]
        : plan;
    final oldFollowRate = _marketFollowerRate(oldBase, oldPlan, index);
    final newFollowRate = _marketFollowerRate(newBase, plan, index);

    if (_shouldFollowMarket(oldPlan.manualDisplayRatePer10g, oldFollowRate)) {
      plans.add(plan.copyWith(manualDisplayRatePer10g: newFollowRate));
    } else {
      plans.add(plan);
    }
  }

  return next.copyWith(purityPlans: plans);
}

double _marketFollowerRate(
  double base,
  MetalRatePurityPlan plan,
  int index,
) {
  if (base <= 0) {
    return 0.0;
  }
  final key = _purityKey(plan.label);
  if (index == 0 || key == '24K' || key == '999') {
    return base;
  }
  final value = base * plan.purityFactor;
  return ((value / 10).round() * 10).toDouble();
}

bool _shouldFollowMarket(double currentRate, double oldFollowRate) {
  if (currentRate <= 0) {
    return true;
  }
  if (oldFollowRate <= 0) {
    return false;
  }
  final tolerance = oldFollowRate * 0.03;
  final safeTolerance = tolerance < 100 ? 100 : tolerance;
  return (currentRate - oldFollowRate).abs() <= safeTolerance;
}

String _purityKey(String value) {
  return value.trim().toUpperCase().replaceAll('KT', 'K');
}
