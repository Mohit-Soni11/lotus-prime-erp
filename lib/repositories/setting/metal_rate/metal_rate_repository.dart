import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';

/// Single database-backed source for rate configuration and its audit history.
/// SharedPreferences is read once only to import an existing installation.
class MetalRateRepository {
  MetalRateRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  static const _legacyProfilesKey = 'metal_rate_profiles_v2';
  static const _historyLimit = 25;
  final AppDatabase _db;

  Future<List<MetalRateProfile>> loadProfiles() async {
    await _ensureLedgerInitialised();
    return _readCurrentProfiles();
  }

  Future<MetalRateProfile> loadProfile(MetalRateMetal metal) async {
    final profiles = await loadProfiles();
    return profiles.firstWhere((profile) => profile.metal == metal);
  }

  Stream<List<MetalRateProfile>> watchProfiles() async* {
    await _ensureLedgerInitialised();
    yield await _readCurrentProfiles();
    yield* _db.select(_db.metalRateProfiles).watch().asyncMap(
          (_) => _readCurrentProfiles(),
        );
  }

  Future<void> saveProfile(
    MetalRateProfile profile, {
    String? changeReason,
  }) async {
    _validateProfile(profile);
    final now = DateTime.now();
    final updated = profile.copyWith(updatedAt: now);
    final payload = jsonEncode(updated.toJson());

    await _db.transaction(() async {
      final existing = await (_db.select(_db.metalRateProfiles)
            ..where((table) => table.metalKey.equals(updated.metal.key)))
          .getSingleOrNull();
      final revision = (existing?.revision ?? 0) + 1;
      final source = _sourceFor(updated);

      if (existing == null) {
        await _db.into(_db.metalRateProfiles).insert(
              MetalRateProfilesCompanion.insert(
                metalKey: updated.metal.key,
                profileJson: payload,
                revision: Value(revision),
                source: Value(source),
                updatedAt: Value(now),
              ),
            );
      } else {
        await (_db.update(_db.metalRateProfiles)
              ..where((table) => table.id.equals(existing.id)))
            .write(MetalRateProfilesCompanion(
          profileJson: Value(payload),
          revision: Value(revision),
          source: Value(source),
          updatedAt: Value(now),
        ));
      }

      await _db.into(_db.metalRateRevisions).insert(
            MetalRateRevisionsCompanion.insert(
              metalKey: updated.metal.key,
              revision: revision,
              profileJson: payload,
              source: source,
              changeReason: Value(changeReason?.trim().isEmpty ?? true
                  ? null
                  : changeReason!.trim()),
              effectiveAt: now,
            ),
          );
    });
  }

  Future<void> resetProfile(MetalRateMetal metal) => saveProfile(
        MetalRateProfile.defaultFor(metal),
        changeReason: 'Restored default profile',
      );

  Future<List<MetalRateHistoryEntry>> loadHistory(MetalRateMetal metal) async {
    await _ensureLedgerInitialised();
    final rows = await (_db.select(_db.metalRateRevisions)
          ..where((table) => table.metalKey.equals(metal.key))
          ..orderBy([(table) => OrderingTerm.desc(table.revision)])
          ..limit(_historyLimit))
        .get();
    return rows
        .map((row) => MetalRateHistoryEntry(
              profile: _profileFromPayload(row.profileJson, metal),
              changedAt: row.effectiveAt,
              source: row.source,
            ))
        .toList(growable: false);
  }

  Future<void> _ensureLedgerInitialised() async {
    final existing =
        await (_db.select(_db.metalRateProfiles)..limit(1)).getSingleOrNull();
    if (existing != null) return;

    final imported = await _readLegacyProfiles();
    final legacyDailyRate = await (_db.select(_db.dailyRates)
          ..orderBy([(table) => OrderingTerm.desc(table.rateDate)])
          ..limit(1))
        .getSingleOrNull();
    await _db.transaction(() async {
      final alreadyInitialised =
          await (_db.select(_db.metalRateProfiles)..limit(1)).getSingleOrNull();
      if (alreadyInitialised != null) return;

      final now = DateTime.now();
      for (final metal in MetalRateMetal.values) {
        final importedProfile = imported[metal] ??
            _profileFromLegacyDailyRate(metal, legacyDailyRate) ??
            MetalRateProfile.defaultFor(metal);
        final profile = importedProfile.copyWith(updatedAt: now);
        final payload = jsonEncode(profile.toJson());
        final source = _sourceFor(profile);
        await _db.into(_db.metalRateProfiles).insert(
              MetalRateProfilesCompanion.insert(
                metalKey: metal.key,
                profileJson: payload,
                revision: const Value(1),
                source: Value(source),
                updatedAt: Value(now),
              ),
            );
        await _db.into(_db.metalRateRevisions).insert(
              MetalRateRevisionsCompanion.insert(
                metalKey: metal.key,
                revision: 1,
                profileJson: payload,
                source: source,
                changeReason: const Value('Migrated to rate ledger'),
                effectiveAt: now,
              ),
            );
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyProfilesKey);
  }

  Future<Map<MetalRateMetal, MetalRateProfile>> _readLegacyProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyProfilesKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final profiles = <MetalRateMetal, MetalRateProfile>{};
      for (final entry in decoded.whereType<Map>()) {
        final profile = MetalRateProfile.fromJson(
          Map<String, dynamic>.from(entry),
        );
        profiles[profile.metal] = profile;
      }
      return profiles;
    } catch (_) {
      return const {};
    }
  }

  MetalRateProfile? _profileFromLegacyDailyRate(
    MetalRateMetal metal,
    DailyRate? rate,
  ) {
    if (rate == null ||
        (metal != MetalRateMetal.gold && metal != MetalRateMetal.silver)) {
      return null;
    }

    final base = MetalRateProfile.defaultFor(metal);
    if (metal == MetalRateMetal.gold) {
      final gold24 = _parseRate(rate.gold24k);
      final gold22 = _parseRate(rate.gold22k);
      final gold18 = _parseRate(rate.gold18k);
      if ([gold24, gold22, gold18].every((value) => value <= 0)) return null;
      return base.copyWith(
        marketSource: rate.source,
        physicalMarketRatePer10g: gold24,
        marketRatePer10g: gold24,
        updatedAt: rate.updatedAt ?? rate.rateDate,
        purityPlans: base.purityPlans
            .map(
              (plan) => switch (plan.label) {
                '24K' => plan.copyWith(
                    manualDisplayRatePer10g: gold24,
                    buyRatePer10g: _parseRate(rate.oldGold24kBuy),
                  ),
                '22K' => plan.copyWith(
                    manualDisplayRatePer10g: gold22,
                    buyRatePer10g: _parseRate(rate.oldGold22kBuy),
                  ),
                '18K' => plan.copyWith(
                    manualDisplayRatePer10g: gold18,
                    buyRatePer10g: _parseRate(rate.oldGold18kBuy),
                  ),
                _ => plan,
              },
            )
            .toList(growable: false),
      );
    }

    final silver999 = _parseRate(rate.silverIdols) > 0
        ? _parseRate(rate.silverIdols)
        : _parseRate(rate.silverRateKg) / 100;
    final silver925 = _parseRate(rate.silverJewellery);
    if (silver999 <= 0 && silver925 <= 0) return null;
    return base.copyWith(
      marketSource: rate.source,
      physicalMarketRatePer10g: silver999 > 0 ? silver999 : silver925,
      marketRatePer10g: silver999 > 0 ? silver999 : silver925,
      updatedAt: rate.updatedAt ?? rate.rateDate,
      purityPlans: base.purityPlans
          .map(
            (plan) => switch (plan.label) {
              '999' => plan.copyWith(
                  manualDisplayRatePer10g: silver999,
                  buyRatePer10g: _parseRate(rate.oldSilverBuy),
                ),
              '925' => plan.copyWith(manualDisplayRatePer10g: silver925),
              _ => plan,
            },
          )
          .toList(growable: false),
    );
  }

  Future<List<MetalRateProfile>> _readCurrentProfiles() async {
    final rows = await _db.select(_db.metalRateProfiles).get();
    final byMetal = <MetalRateMetal, MetalRateProfile>{};
    for (final row in rows) {
      final metal = MetalRateMetalX.fromKey(row.metalKey);
      byMetal[metal] = _profileFromPayload(row.profileJson, metal);
    }
    return MetalRateMetal.values
        .map((metal) => byMetal[metal] ?? MetalRateProfile.defaultFor(metal))
        .toList(growable: false);
  }

  MetalRateProfile _profileFromPayload(String payload, MetalRateMetal metal) {
    try {
      return MetalRateProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(payload) as Map),
      );
    } catch (_) {
      return MetalRateProfile.defaultFor(metal);
    }
  }

  void _validateProfile(MetalRateProfile profile) {
    final values = <double>[
      profile.mcxRatePer10g,
      profile.physicalMarketRatePer10g,
      profile.marketRatePer10g,
      profile.gstPercent,
      profile.importDutyPercent,
      profile.logisticsPercent,
      profile.wastageBufferPercent,
      profile.holdingCostPercent,
      profile.competitiveDiscountPercent,
      profile.minimumMarginPercent,
      ...profile.purityPlans.expand((plan) => [
            plan.purityPercent,
            plan.supplierPremiumPercent,
            plan.targetMarginPercent,
            plan.landedCostOverridePer10g,
            plan.manualDisplayRatePer10g,
            plan.buyRatePer10g,
            plan.supplierBillingPercent,
            plan.shopMarkupPercent,
            plan.makingChargePercent,
            plan.makingChargePerGram,
          ]),
    ];
    if (values.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError('Rate profile contains an invalid numeric value.');
    }
  }

  String _sourceFor(MetalRateProfile profile) {
    final source = profile.marketSource.trim();
    return source.isEmpty ? 'Manual' : source;
  }

  double _parseRate(String value) =>
      double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
}
