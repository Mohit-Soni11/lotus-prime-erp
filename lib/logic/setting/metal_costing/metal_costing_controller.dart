// =============================================================================
// FILE        : lib/logic/metal_costing/metal_costing_controller.dart
// MODULE      : Metal Costing Analysis
// LAYER       : Logic / Controller
// DESCRIPTION : ChangeNotifier controller for Metal Costing screens.
//               Loads stock data, injects today's rates, builds summaries.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import '../../../database/db/app_database.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../models/setting/metal_costing/metal_costing_model.dart';
import '../../../repositories/setting/metal_costing/metal_costing_repository.dart';
import '../../../repositories/setting/metal_rate/metal_rate_repository.dart';

enum MetalCostingState { idle, loading, loaded, error }

class MetalCostingController extends ChangeNotifier {
  final MetalCostingRepository _repo;
  final AppDatabase _db;

  MetalCostingController({
    MetalCostingRepository? repo,
    AppDatabase? db,
  })  : _repo = repo ?? MetalCostingRepository(AppDatabase()),
        _db = db ?? AppDatabase() {
    loadData();
  }

  // ── State ──────────────────────────────────────────────────────────────────
  MetalCostingState _state = MetalCostingState.idle;
  String? _error;
  List<MetalSummary> _summaries = [];

  MetalCostingState get state => _state;
  String? get error => _error;
  List<MetalSummary> get summaries => _summaries;

  // ── Today's rates (per 100g) ──────────────────────────────────────────────
  Map<String, double> _todayRates = {
    'gold': 0.0,
    'silver': 0.0,
    'platinum': 0.0,
    'diamond': 0.0,
  };
  Map<String, double> get todayRates => _todayRates;

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> loadData() async {
    _state = MetalCostingState.loading;
    _error = null;
    notifyListeners();

    try {
      // 1. Get latest daily rate from DB
      final metalRateProfiles = await MetalRateRepository().loadProfiles();
      final profileRates = {
        for (final profile in metalRateProfiles)
          profile.metal.key: profile.primaryShopRatePer10g > 0
              ? profile.primaryShopRatePer10g * 10
              : 0.0,
      };

      final rateQuery = _db.select(_db.dailyRates)
        ..orderBy([(r) => drift.OrderingTerm.desc(r.rateDate)])
        ..limit(1);
      final rates = await rateQuery.get();

      if (rates.isNotEmpty) {
        final row = rates.first;
        // DB stores per 10g — ×10 for per 100g
        final g24 = (double.tryParse(row.gold24k) ?? 0) * 10;
        final sil = (double.tryParse(row.silverJewellery) ?? 0) * 10;
        _todayRates = {
          'gold': _positive(profileRates[MetalRateMetal.gold.key], g24),
          'silver': _positive(profileRates[MetalRateMetal.silver.key], sil),
          'platinum': _positive(profileRates[MetalRateMetal.platinum.key], 0),
          'diamond': _positive(profileRates[MetalRateMetal.diamond.key], 0),
        };
      } else {
        _todayRates = {
          'gold': profileRates[MetalRateMetal.gold.key] ?? 0.0,
          'silver': profileRates[MetalRateMetal.silver.key] ?? 0.0,
          'platinum': profileRates[MetalRateMetal.platinum.key] ?? 0.0,
          'diamond': profileRates[MetalRateMetal.diamond.key] ?? 0.0,
        };
      }

      // 2. Build purity + item summaries from stock DB
      _summaries = await _repo.buildSummary(todayRates: _todayRates);

      _state = MetalCostingState.loaded;
    } catch (e, st) {
      debugPrint('MetalCostingController error: $e\n$st');
      _error = e.toString();
      _state = MetalCostingState.error;
    }

    notifyListeners();
  }

  Future<void> refresh() => loadData();

  // ── Getters ────────────────────────────────────────────────────────────────
  MetalSummary? getSummaryByMetal(String metal) {
    try {
      return _summaries.firstWhere(
        (s) => s.metalType.toLowerCase() == metal.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  PuritySummary? getPuritySummary(String metal, String purity) {
    final ms = getSummaryByMetal(metal);
    if (ms == null) return null;
    try {
      return ms.purities.firstWhere((p) => p.purity == purity);
    } catch (_) {
      return null;
    }
  }

  double getTodayRateForMetal(String metal) =>
      _todayRates[metal.toLowerCase()] ?? 0.0;
}

double _positive(double? value, double fallback) {
  if (value != null && value > 0) {
    return value;
  }
  return fallback;
}
