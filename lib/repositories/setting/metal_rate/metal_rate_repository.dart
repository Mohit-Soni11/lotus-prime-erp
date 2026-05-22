// =============================================================================
// FILE        : lib/repositories/setting/metal_rate/metal_rate_repository.dart
// MODULE      : Metal Rate Setting
// LAYER       : Repository / Data Access
// DESCRIPTION : Persists daily metal rate profiles and compact history locally.
// =============================================================================

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/db/app_database.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';

class MetalRateRepository {
  static const String _profilesKey = 'metal_rate_profiles_v2';
  static const String _historyKey = 'metal_rate_history_v2';
  static const String _historyTable = 'metal_rate_history';
  static const int _historyLimit = 25;

  final AppDatabase _db;

  MetalRateRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<List<MetalRateProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    final profiles = <MetalRateProfile>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        profiles.addAll(
          decoded
              .whereType<Map>()
              .map(
                (item) => MetalRateProfile.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
      } catch (_) {
        profiles.clear();
      }
    }

    final existingKeys = profiles.map((profile) => profile.metal.key).toSet();
    for (final metal in MetalRateMetal.values) {
      if (!existingKeys.contains(metal.key)) {
        profiles.add(MetalRateProfile.defaultFor(metal));
      }
    }

    await _mergeLatestDailyRate(profiles);
    await _writeProfiles(prefs, profiles);
    return profiles;
  }

  Future<MetalRateProfile> loadProfile(MetalRateMetal metal) async {
    final profiles = await loadProfiles();
    return profiles.firstWhere(
      (profile) => profile.metal == metal,
      orElse: () => MetalRateProfile.defaultFor(metal),
    );
  }

  Future<void> saveProfile(MetalRateProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await loadProfiles();
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    final index = profiles.indexWhere((item) => item.metal == profile.metal);

    if (index == -1) {
      profiles.add(updatedProfile);
    } else {
      profiles[index] = updatedProfile;
    }

    await _writeProfiles(prefs, profiles);
    await _syncDailyRate(updatedProfile);
    await _appendHistory(prefs, updatedProfile);
  }

  Future<void> resetProfile(MetalRateMetal metal) async {
    await saveProfile(MetalRateProfile.defaultFor(metal));
  }

  Future<List<MetalRateHistoryEntry>> loadHistory(MetalRateMetal metal) async {
    final databaseHistory = await _loadDatabaseHistory(metal);
    if (databaseHistory.isNotEmpty) {
      return databaseHistory;
    }

    final dailyHistory = await _loadDailyRateHistory(metal);
    if (dailyHistory.isNotEmpty) {
      return dailyHistory;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .whereType<Map>()
          .map(
            (item) => MetalRateHistoryEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((entry) => entry.profile.metal == metal)
          .toList();
      entries.sort((a, b) => b.changedAt.compareTo(a.changedAt));
      return entries.take(_historyLimit).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeProfiles(
    SharedPreferences prefs,
    List<MetalRateProfile> profiles,
  ) {
    return prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  Future<void> _ensureHistoryTable() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS "$_historyTable" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "metal" TEXT NOT NULL,
        "rate_date" INTEGER NOT NULL,
        "profile_json" TEXT NOT NULL,
        "source" TEXT NOT NULL,
        "created_at" INTEGER NOT NULL
      )
    ''');
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_${_historyTable}_metal_date" '
      'ON "$_historyTable" ("metal", "rate_date" DESC)',
    );
  }

  Future<List<MetalRateHistoryEntry>> _loadDatabaseHistory(
    MetalRateMetal metal,
  ) async {
    await _ensureHistoryTable();

    final rows = await _db.customSelect(
      'SELECT profile_json, rate_date, source FROM "$_historyTable" '
      'WHERE metal = ? ORDER BY rate_date DESC LIMIT ?',
      variables: [
        Variable.withString(metal.key),
        Variable.withInt(_historyLimit),
      ],
    ).get();

    return rows
        .map((row) {
          try {
            final profileJson = row.read<String>('profile_json');
            final profile = MetalRateProfile.fromJson(
              Map<String, dynamic>.from(jsonDecode(profileJson) as Map),
            );
            return MetalRateHistoryEntry(
              profile: profile,
              changedAt: DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('rate_date'),
              ),
              source: row.read<String>('source'),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<MetalRateHistoryEntry>()
        .toList(growable: false);
  }

  Future<void> _mergeLatestDailyRate(List<MetalRateProfile> profiles) async {
    final latest = await _latestDailyRate();
    if (latest == null) {
      return;
    }

    for (var i = 0; i < profiles.length; i++) {
      final metal = profiles[i].metal;
      if (metal == MetalRateMetal.gold || metal == MetalRateMetal.silver) {
        profiles[i] = _profileFromDailyRate(metal, latest, profiles[i]);
      }
    }
  }

  Future<DailyRate?> _latestDailyRate() {
    return (_db.select(_db.dailyRates)
          ..orderBy([(table) => OrderingTerm.desc(table.rateDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<MetalRateHistoryEntry>> _loadDailyRateHistory(
    MetalRateMetal metal,
  ) async {
    if (metal != MetalRateMetal.gold && metal != MetalRateMetal.silver) {
      return const [];
    }

    final rows = await (_db.select(_db.dailyRates)
          ..orderBy([(table) => OrderingTerm.desc(table.rateDate)])
          ..limit(_historyLimit))
        .get();

    return rows
        .map(
          (row) => MetalRateHistoryEntry(
            profile: _profileFromDailyRate(
              metal,
              row,
              MetalRateProfile.defaultFor(metal),
            ),
            changedAt: row.updatedAt ?? row.rateDate,
            source: row.source,
          ),
        )
        .toList(growable: false);
  }

  MetalRateProfile _profileFromDailyRate(
    MetalRateMetal metal,
    DailyRate row,
    MetalRateProfile base,
  ) {
    final updatedAt = row.updatedAt ?? row.rateDate;
    if (metal == MetalRateMetal.gold) {
      final gold24 = _toDouble(row.gold24k);
      final gold22 = _toDouble(row.gold22k);
      final gold18 = _toDouble(row.gold18k);
      final old24 = _toDouble(row.oldGold24kBuy);
      final old22 = _toDouble(row.oldGold22kBuy);
      final old18 = _toDouble(row.oldGold18kBuy);

      return base.copyWith(
        marketSource: row.source,
        physicalMarketRatePer10g: gold24,
        marketRatePer10g: gold24,
        updatedAt: updatedAt,
        purityPlans: base.purityPlans
            .map(
              (plan) => switch (_planKey(plan.label)) {
                '24K' => plan.copyWith(
                    manualDisplayRatePer10g: gold24,
                    buyRatePer10g: old24,
                  ),
                '22K' => plan.copyWith(
                    manualDisplayRatePer10g: gold22,
                    buyRatePer10g: old22,
                  ),
                '18K' => plan.copyWith(
                    manualDisplayRatePer10g: gold18,
                    buyRatePer10g: old18,
                  ),
                _ => plan,
              },
            )
            .toList(growable: false),
      );
    }

    final silverKg = _toDouble(row.silverRateKg);
    final silverJewellery = _toDouble(row.silverJewellery);
    final silverPer10g = silverJewellery > 0 ? silverJewellery : silverKg / 100;
    final oldSilver = _toDouble(row.oldSilverBuy);

    return base.copyWith(
      marketSource: row.source,
      physicalMarketRatePer10g: silverPer10g,
      marketRatePer10g: silverPer10g,
      updatedAt: updatedAt,
      purityPlans: base.purityPlans
          .asMap()
          .entries
          .map(
            (entry) => entry.key == 0
                ? entry.value.copyWith(
                    manualDisplayRatePer10g: silverPer10g,
                    buyRatePer10g: oldSilver,
                  )
                : entry.value,
          )
          .toList(growable: false),
    );
  }

  Future<void> _syncDailyRate(MetalRateProfile profile) async {
    if (profile.metal != MetalRateMetal.gold &&
        profile.metal != MetalRateMetal.silver) {
      return;
    }

    final date = _dateOnly(profile.updatedAt);
    final existing = await (_db.select(_db.dailyRates)
          ..where((table) => table.rateDate.equals(date)))
        .getSingleOrNull();

    String value(String? existingValue) => existingValue ?? '0';

    var gold24 = value(existing?.gold24k);
    var gold22 = value(existing?.gold22k);
    var gold18 = value(existing?.gold18k);
    var oldGold24 = value(existing?.oldGold24kBuy);
    var oldGold22 = value(existing?.oldGold22kBuy);
    var oldGold18 = value(existing?.oldGold18kBuy);
    var silverKg = value(existing?.silverRateKg);
    var silverJewellery = value(existing?.silverJewellery);
    var silverIdols = value(existing?.silverIdols);
    var oldSilver = value(existing?.oldSilverBuy);

    if (profile.metal == MetalRateMetal.gold) {
      gold24 = _rateText(_planSellRate(profile, '24K'));
      gold22 = _rateText(_planSellRate(profile, '22K'));
      gold18 = _rateText(_planSellRate(profile, '18K'));
      oldGold24 = _rateText(_planBuyRate(profile, '24K'));
      oldGold22 = _rateText(_planBuyRate(profile, '22K'));
      oldGold18 = _rateText(_planBuyRate(profile, '18K'));
    } else if (profile.metal == MetalRateMetal.silver) {
      final sell = profile.purityPlans.isEmpty
          ? profile.marketBaseRatePer10g
          : profile.purityPlans.first.manualDisplayRatePer10g;
      final buy = profile.purityPlans.isEmpty
          ? 0.0
          : profile.purityPlans.first.buyRatePer10g;
      silverJewellery = _rateText(sell);
      silverIdols = _rateText(sell);
      silverKg = _rateText(sell * 100);
      oldSilver = _rateText(buy);
    }

    await _db.into(_db.dailyRates).insertOnConflictUpdate(
          DailyRatesCompanion(
            rateDate: Value(date),
            gold24k: Value(gold24),
            gold22k: Value(gold22),
            gold18k: Value(gold18),
            silverRateKg: Value(silverKg),
            silverJewellery: Value(silverJewellery),
            silverIdols: Value(silverIdols),
            oldGold24kBuy: Value(oldGold24),
            oldGold22kBuy: Value(oldGold22),
            oldGold18kBuy: Value(oldGold18),
            oldSilverBuy: Value(oldSilver),
            source: const Value('Metal Rate Master'),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _appendHistory(
    SharedPreferences prefs,
    MetalRateProfile profile,
  ) async {
    final raw = prefs.getString(_historyKey);
    final entries = <MetalRateHistoryEntry>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        entries.addAll(
          decoded
              .whereType<Map>()
              .map(
                (item) => MetalRateHistoryEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
      } catch (_) {
        entries.clear();
      }
    }

    entries.insert(
      0,
      MetalRateHistoryEntry(
        profile: profile,
        changedAt: profile.updatedAt,
        source: profile.marketSource,
      ),
    );

    await _ensureHistoryTable();
    await _db.customStatement(
      'INSERT INTO "$_historyTable" '
      '(metal, rate_date, profile_json, source, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        profile.metal.key,
        profile.updatedAt.millisecondsSinceEpoch,
        jsonEncode(profile.toJson()),
        profile.marketSource,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );

    final compact = entries.take(_historyLimit * MetalRateMetal.values.length);
    await prefs.setString(
      _historyKey,
      jsonEncode(compact.map((entry) => entry.toJson()).toList()),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _planKey(String label) =>
    label.trim().toUpperCase().replaceAll('KT', 'K');

double _planSellRate(MetalRateProfile profile, String label) {
  final key = _planKey(label);
  for (final plan in profile.purityPlans) {
    if (_planKey(plan.label) == key) {
      return plan.manualDisplayRatePer10g;
    }
  }
  return 0.0;
}

double _planBuyRate(MetalRateProfile profile, String label) {
  final key = _planKey(label);
  for (final plan in profile.purityPlans) {
    if (_planKey(plan.label) == key) {
      return plan.buyRatePer10g;
    }
  }
  return 0.0;
}

double _toDouble(String value) =>
    double.tryParse(value.replaceAll(',', '')) ?? 0.0;

String _rateText(double value) {
  if (value <= 0) {
    return '0';
  }
  final rounded = value.roundToDouble();
  return rounded == value ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
