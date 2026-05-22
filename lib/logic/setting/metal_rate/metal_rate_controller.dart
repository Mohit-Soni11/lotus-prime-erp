// =============================================================================
// FILE        : lib/logic/setting/metal_rate/metal_rate_controller.dart
// MODULE      : Metal Rate Setting
// LAYER       : Logic / Controller
// DESCRIPTION : ChangeNotifier controller for smart rate hub and detail screens.
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

  MetalRateLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  List<MetalRateProfile> get profiles =>
      MetalRateMetal.values.map(profileFor).toList(growable: false);

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

  void updateMarketRate(MetalRateMetal metal, double value) {
    final profile = profileFor(metal);
    final safeValue = value.clamp(0, 9999999).toDouble();
    stageProfile(
      profile.copyWith(
        mcxRatePer10g: safeValue,
        physicalMarketRatePer10g: safeValue,
        marketRatePer10g: safeValue,
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
    );
    stageProfile(next.copyWith(marketRatePer10g: next.marketBaseRatePer10g));
  }

  void updatePercent({
    required MetalRateMetal metal,
    double? gst,
    double? importDuty,
    double? logistics,
    double? wastage,
    double? holding,
    double? competitiveDiscount,
    double? minimumMargin,
  }) {
    final profile = profileFor(metal);
    stageProfile(
      profile.copyWith(
        gstPercent: gst?.clamp(0, 99).toDouble(),
        importDutyPercent: importDuty?.clamp(0, 99).toDouble(),
        logisticsPercent: logistics?.clamp(0, 99).toDouble(),
        wastageBufferPercent: wastage?.clamp(0, 99).toDouble(),
        holdingCostPercent: holding?.clamp(0, 99).toDouble(),
        competitiveDiscountPercent:
            competitiveDiscount?.clamp(0, 20).toDouble(),
        minimumMarginPercent: minimumMargin?.clamp(0, 50).toDouble(),
      ),
    );
  }

  void updatePosture(MetalRateMetal metal, PricingPosture posture) {
    final profile = profileFor(metal);
    stageProfile(profile.copyWith(posture: posture));
  }

  void updatePurityPlan({
    required MetalRateMetal metal,
    required int index,
    double? supplierPremium,
    double? targetMargin,
    double? landedCost,
    double? displayRate,
    double? makingPercent,
    double? makingPerGram,
  }) {
    final profile = profileFor(metal);
    if (index < 0 || index >= profile.purityPlans.length) {
      return;
    }

    final plans = List<MetalRatePurityPlan>.from(profile.purityPlans);
    plans[index] = plans[index].copyWith(
      supplierPremiumPercent: supplierPremium?.clamp(0, 50).toDouble(),
      targetMarginPercent: targetMargin?.clamp(0, 80).toDouble(),
      landedCostOverridePer10g: landedCost?.clamp(0, 9999999).toDouble(),
      manualDisplayRatePer10g: displayRate?.clamp(0, 9999999).toDouble(),
      makingChargePercent: makingPercent?.clamp(0, 99).toDouble(),
      makingChargePerGram: makingPerGram?.clamp(0, 999999).toDouble(),
    );
    stageProfile(profile.copyWith(purityPlans: plans));
  }

  void updateBrandBenchmark({
    required MetalRateMetal metal,
    required int index,
    double? referenceRate,
    double? makingLow,
    double? makingHigh,
    String? purityLabel,
    double? purityRate,
    double? purityMaking,
  }) {
    final profile = profileFor(metal);
    if (index < 0 || index >= profile.brandBenchmarks.length) {
      return;
    }

    final benchmarks =
        List<MetalRateBrandBenchmark>.from(profile.brandBenchmarks);
    final current = benchmarks[index];
    final low = makingLow ?? current.makingLowPercent;
    final high = makingHigh ?? current.makingHighPercent;
    final rateByPurity = Map<String, double>.from(current.rateByPurity);
    final makingByPurity = Map<String, double>.from(current.makingByPurity);
    if (purityLabel != null && purityRate != null) {
      rateByPurity[_purityKey(purityLabel)] =
          purityRate.clamp(0, 9999999).toDouble();
    }
    if (purityLabel != null && purityMaking != null) {
      makingByPurity[_purityKey(purityLabel)] =
          purityMaking.clamp(0, 99).toDouble();
    }

    benchmarks[index] = current.copyWith(
      referenceRatePer10g: referenceRate?.clamp(0, 9999999).toDouble(),
      makingLowPercent: low.clamp(0, 99).toDouble(),
      makingHighPercent: high.clamp(0, 99).toDouble(),
      rateByPurity: rateByPurity,
      makingByPurity: makingByPurity,
    );
    stageProfile(profile.copyWith(brandBenchmarks: benchmarks));
  }
}

String _purityKey(String value) {
  return value.trim().toUpperCase().replaceAll('KT', 'K');
}
