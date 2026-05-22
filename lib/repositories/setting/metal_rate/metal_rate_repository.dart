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
                (item) =>
                    MetalRateProfile.fromJson(Map<String, dynamic>.from(item)),
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
            (item) =>
                MetalRateHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
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
        "metal_key" TEXT NOT NULL,
        "rate_date" INTEGER NOT NULL,
        "profile_json" TEXT NOT NULL,
        "snapshot_json" TEXT NOT NULL,
        "source" TEXT NOT NULL,
        "created_at" INTEGER NOT NULL
      )
    ''');

    final columns = await _historyTableColumns();

    Future<void> addMissingColumn(String name, String definition) async {
      if (columns.contains(name)) {
        return;
      }

      await _db.customStatement(
        'ALTER TABLE "$_historyTable" ADD COLUMN "$name" $definition',
      );
      columns.add(name);
    }

    await addMissingColumn('metal', 'TEXT');
    await addMissingColumn('metal_key', 'TEXT');
    await addMissingColumn('rate_date', 'INTEGER');
    await addMissingColumn('profile_json', 'TEXT');
    await addMissingColumn('snapshot_json', 'TEXT');
    await addMissingColumn('source', 'TEXT');
    await addMissingColumn('created_at', 'INTEGER');

    if (columns.contains('metal') && columns.contains('metal_key')) {
      await _db.customStatement(
        'UPDATE "$_historyTable" SET "metal" = "metal_key" '
        'WHERE ("metal" IS NULL OR "metal" = \'\') '
        'AND "metal_key" IS NOT NULL',
      );
      await _db.customStatement(
        'UPDATE "$_historyTable" SET "metal_key" = "metal" '
        'WHERE ("metal_key" IS NULL OR "metal_key" = \'\') '
        'AND "metal" IS NOT NULL',
      );
    }

    if (columns.contains('profile_json') && columns.contains('snapshot_json')) {
      await _db.customStatement(
        'UPDATE "$_historyTable" SET "profile_json" = "snapshot_json" '
        'WHERE ("profile_json" IS NULL OR "profile_json" = \'\') '
        'AND "snapshot_json" IS NOT NULL',
      );
      await _db.customStatement(
        'UPDATE "$_historyTable" SET "snapshot_json" = "profile_json" '
        'WHERE ("snapshot_json" IS NULL OR "snapshot_json" = \'\') '
        'AND "profile_json" IS NOT NULL',
      );
    }

    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_${_historyTable}_metal_date" '
      'ON "$_historyTable" ("metal", "rate_date" DESC)',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_${_historyTable}_metal_key_date" '
      'ON "$_historyTable" ("metal_key", "rate_date" DESC)',
    );
  }

  Future<Set<String>> _historyTableColumns() async {
    final rows = await _db.customSelect(
      'PRAGMA table_info("$_historyTable")',
      readsFrom: const {},
    ).get();

    return rows.map((row) => row.data['name']).whereType<String>().toSet();
  }

  Future<List<MetalRateHistoryEntry>> _loadDatabaseHistory(
    MetalRateMetal metal,
  ) async {
    await _ensureHistoryTable();
    final columns = await _historyTableColumns();
    final hasMetalKey = columns.contains('metal_key');

    final rows = await _db.customSelect(
      'SELECT profile_json, snapshot_json, rate_date, source '
      'FROM "$_historyTable" '
      'WHERE ${hasMetalKey ? '(metal = ? OR metal_key = ?)' : 'metal = ?'} '
      'ORDER BY rate_date DESC LIMIT ?',
      variables: [
        Variable.withString(metal.key),
        if (hasMetalKey) Variable.withString(metal.key),
        Variable.withInt(_historyLimit),
      ],
    ).get();

    return rows
        .map((row) {
          try {
            final profileJson = (row.data['profile_json'] ??
                row.data['snapshot_json']) as String?;
            if (profileJson == null || profileJson.isEmpty) {
              return null;
            }
            final profile = MetalRateProfile.fromJson(
              Map<String, dynamic>.from(jsonDecode(profileJson) as Map),
            );
            return MetalRateHistoryEntry(
              profile: profile,
              changedAt: DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('rate_date'),
              ),
              source: row.data['source'] as String? ?? 'Metal Rate Master',
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
    final updatedAt = DateTime.now();

    if (profile.metal == MetalRateMetal.gold) {
      await _upsertGoldDailyRate(
        rateDate: date,
        updatedAt: updatedAt,
        gold24: _rateText(_planSellRate(profile, '24K')),
        gold22: _rateText(_planSellRate(profile, '22K')),
        gold18: _rateText(_planSellRate(profile, '18K')),
        oldGold24: _rateText(_planBuyRate(profile, '24K')),
        oldGold22: _rateText(_planBuyRate(profile, '22K')),
        oldGold18: _rateText(_planBuyRate(profile, '18K')),
      );
      return;
    }

    final sell = profile.purityPlans.isEmpty
        ? profile.marketBaseRatePer10g
        : profile.purityPlans.first.manualDisplayRatePer10g;
    final buy = profile.purityPlans.isEmpty
        ? 0.0
        : profile.purityPlans.first.buyRatePer10g;

    await _upsertSilverDailyRate(
      rateDate: date,
      updatedAt: updatedAt,
      silverKg: _rateText(sell * 100),
      silverJewellery: _rateText(sell),
      silverIdols: _rateText(sell),
      oldSilver: _rateText(buy),
    );
  }

  Future<void> _upsertGoldDailyRate({
    required DateTime rateDate,
    required DateTime updatedAt,
    required String gold24,
    required String gold22,
    required String gold18,
    required String oldGold24,
    required String oldGold22,
    required String oldGold18,
  }) {
    return _db.customUpdate(
      '''
      INSERT INTO "daily_rates" (
        "rate_date",
        "gold24k",
        "gold22k",
        "gold18k",
        "old_gold24k_buy",
        "old_gold22k_buy",
        "old_gold18k_buy",
        "source",
        "updated_at"
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT("rate_date") DO UPDATE SET
        "gold24k" = excluded."gold24k",
        "gold22k" = excluded."gold22k",
        "gold18k" = excluded."gold18k",
        "old_gold24k_buy" = excluded."old_gold24k_buy",
        "old_gold22k_buy" = excluded."old_gold22k_buy",
        "old_gold18k_buy" = excluded."old_gold18k_buy",
        "source" = excluded."source",
        "updated_at" = excluded."updated_at"
      ''',
      variables: [
        Variable.withDateTime(rateDate),
        Variable.withString(gold24),
        Variable.withString(gold22),
        Variable.withString(gold18),
        Variable.withString(oldGold24),
        Variable.withString(oldGold22),
        Variable.withString(oldGold18),
        Variable.withString('Metal Rate Master'),
        Variable.withDateTime(updatedAt),
      ],
      updates: {_db.dailyRates},
    ).then((_) {});
  }

  Future<void> _upsertSilverDailyRate({
    required DateTime rateDate,
    required DateTime updatedAt,
    required String silverKg,
    required String silverJewellery,
    required String silverIdols,
    required String oldSilver,
  }) {
    return _db.customUpdate(
      '''
      INSERT INTO "daily_rates" (
        "rate_date",
        "silver_rate_kg",
        "silver_jewellery",
        "silver_idols",
        "old_silver_buy",
        "source",
        "updated_at"
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT("rate_date") DO UPDATE SET
        "silver_rate_kg" = excluded."silver_rate_kg",
        "silver_jewellery" = excluded."silver_jewellery",
        "silver_idols" = excluded."silver_idols",
        "old_silver_buy" = excluded."old_silver_buy",
        "source" = excluded."source",
        "updated_at" = excluded."updated_at"
      ''',
      variables: [
        Variable.withDateTime(rateDate),
        Variable.withString(silverKg),
        Variable.withString(silverJewellery),
        Variable.withString(silverIdols),
        Variable.withString(oldSilver),
        Variable.withString('Metal Rate Master'),
        Variable.withDateTime(updatedAt),
      ],
      updates: {_db.dailyRates},
    ).then((_) {});
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
    final columns = await _historyTableColumns();
    final profileJson = jsonEncode(profile.toJson());
    final insertColumns = <String>['metal'];
    final placeholders = <String>['?'];
    final values = <Object?>[profile.metal.key];

    if (columns.contains('metal_key')) {
      insertColumns.add('metal_key');
      placeholders.add('?');
      values.add(profile.metal.key);
    }

    insertColumns.addAll(['rate_date', 'profile_json']);
    placeholders.addAll(const ['?', '?']);
    values.addAll([profile.updatedAt.millisecondsSinceEpoch, profileJson]);

    if (columns.contains('snapshot_json')) {
      insertColumns.add('snapshot_json');
      placeholders.add('?');
      values.add(profileJson);
    }

    insertColumns.addAll(['source', 'created_at']);
    placeholders.addAll(const ['?', '?']);
    values
        .addAll([profile.marketSource, DateTime.now().millisecondsSinceEpoch]);

    await _db.customStatement(
      'INSERT INTO "$_historyTable" '
      '(${insertColumns.map((column) => '"$column"').join(', ')}) '
      'VALUES (${placeholders.join(', ')})',
      values,
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
