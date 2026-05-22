// =============================================================================
// FILE        : lib/repositories/setting/metal_rate/metal_rate_repository.dart
// MODULE      : Metal Rate Setting
// LAYER       : Repository / Data Access
// DESCRIPTION : Owns persistence for smart metal rate profiles and benchmarks.
// =============================================================================

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/db/app_database.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';

class MetalRateRepository {
  final AppDatabase _db;

  MetalRateRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<void> ensureSchema() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS metal_rate_profiles (
        metal_key TEXT NOT NULL PRIMARY KEY,
        profile_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS metal_rate_brand_benchmarks (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        metal_key TEXT NOT NULL,
        brand_name TEXT NOT NULL,
        reference_rate_per10g REAL NOT NULL DEFAULT 0.0,
        making_low_percent REAL NOT NULL DEFAULT 0.0,
        making_high_percent REAL NOT NULL DEFAULT 0.0,
        notes TEXT,
        updated_at INTEGER NOT NULL,
        UNIQUE(metal_key, brand_name)
      )
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_metal_rate_benchmarks_metal
      ON metal_rate_brand_benchmarks (metal_key)
    ''');

    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS metal_rate_history (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        metal_key TEXT NOT NULL,
        snapshot_json TEXT NOT NULL,
        changed_at INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'Manual'
      )
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_metal_rate_history_metal_changed
      ON metal_rate_history (metal_key, changed_at DESC)
    ''');
  }

  Future<List<MetalRateProfile>> loadProfiles() async {
    await ensureSchema();
    final rows = await _db
        .customSelect(
          'SELECT profile_json FROM metal_rate_profiles ORDER BY metal_key',
        )
        .get();

    if (rows.isEmpty) {
      final defaults = MetalRateMetal.values
          .map(MetalRateProfile.defaultFor)
          .toList(growable: false);
      for (final profile in defaults) {
        await saveProfile(profile);
      }
      return defaults;
    }

    final profiles = <MetalRateProfile>[];
    for (final row in rows) {
      try {
        final jsonText = row.read<String>('profile_json');
        final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
        profiles.add(MetalRateProfile.fromJson(decoded));
      } catch (_) {
        // Skip corrupt profile rows; resetDefaults can regenerate them.
      }
    }

    final existingKeys = profiles.map((profile) => profile.metal.key).toSet();
    for (final metal in MetalRateMetal.values) {
      if (!existingKeys.contains(metal.key)) {
        final profile = MetalRateProfile.defaultFor(metal);
        await saveProfile(profile);
        profiles.add(profile);
      }
    }

    return profiles;
  }

  Future<MetalRateProfile> loadProfile(MetalRateMetal metal) async {
    final profiles = await loadProfiles();
    return profiles.firstWhere(
      (profile) => profile.metal == metal,
      orElse: () => MetalRateProfile.defaultFor(metal),
    );
  }

  Future<List<MetalRateHistoryEntry>> loadHistory(
    MetalRateMetal metal, {
    int limit = 8,
  }) async {
    await ensureSchema();
    final rows = await _db.customSelect(
      '''
      SELECT snapshot_json, changed_at, source
      FROM metal_rate_history
      WHERE metal_key = ?
      ORDER BY changed_at DESC
      LIMIT ?
      ''',
      variables: [
        Variable<String>(metal.key),
        Variable<int>(limit),
      ],
    ).get();

    final history = <MetalRateHistoryEntry>[];
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row.read<String>('snapshot_json'))
            as Map<String, dynamic>;
        history.add(
          MetalRateHistoryEntry(
            profile: MetalRateProfile.fromJson(decoded),
            changedAt: DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('changed_at'),
            ),
            source: row.read<String>('source'),
          ),
        );
      } catch (_) {
        // Keep history resilient if an older row is malformed.
      }
    }
    return history;
  }

  Future<void> saveProfile(MetalRateProfile profile) async {
    await ensureSchema();
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    final updatedAt = updatedProfile.updatedAt.millisecondsSinceEpoch;
    final jsonText = jsonEncode(updatedProfile.toJson());

    await _db.transaction(() async {
      await _db.customStatement(
        '''
        INSERT INTO metal_rate_profiles (metal_key, profile_json, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(metal_key)
        DO UPDATE SET profile_json = excluded.profile_json,
                      updated_at = excluded.updated_at
        ''',
        [updatedProfile.metal.key, jsonText, updatedAt],
      );

      await _db.customStatement(
        'DELETE FROM metal_rate_brand_benchmarks WHERE metal_key = ?',
        [updatedProfile.metal.key],
      );

      for (final brand in updatedProfile.brandBenchmarks) {
        await _db.customStatement(
          '''
          INSERT INTO metal_rate_brand_benchmarks (
            metal_key,
            brand_name,
            reference_rate_per10g,
            making_low_percent,
            making_high_percent,
            notes,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(metal_key, brand_name)
          DO UPDATE SET reference_rate_per10g = excluded.reference_rate_per10g,
                        making_low_percent = excluded.making_low_percent,
                        making_high_percent = excluded.making_high_percent,
                        notes = excluded.notes,
                        updated_at = excluded.updated_at
          ''',
          [
            updatedProfile.metal.key,
            brand.brandName,
            brand.referenceRatePer10g,
            brand.makingLowPercent,
            brand.makingHighPercent,
            brand.notes,
            updatedAt,
          ],
        );
      }

      await _db.customStatement(
        '''
        INSERT INTO metal_rate_history (
          metal_key,
          snapshot_json,
          changed_at,
          source
        ) VALUES (?, ?, ?, ?)
        ''',
        [
          updatedProfile.metal.key,
          jsonText,
          updatedAt,
          updatedProfile.marketSource,
        ],
      );
    });

    await _syncDailyRates(updatedProfile);
  }

  Future<void> resetProfile(MetalRateMetal metal) async {
    await saveProfile(MetalRateProfile.defaultFor(metal));
  }

  Future<void> _syncDailyRates(MetalRateProfile profile) async {
    final today = DateTime.now();
    final rateDate = DateTime(today.year, today.month, today.day);

    if (profile.metal == MetalRateMetal.gold) {
      await _db.into(_db.dailyRates).insertOnConflictUpdate(
            DailyRatesCompanion(
              rateDate: Value(rateDate),
              gold24k: Value(_rateFor(profile, '24K')),
              gold22k: Value(_rateFor(profile, '22K')),
              gold18k: Value(_rateFor(profile, '18K')),
              oldGold24kBuy: Value(_buyFor(profile, '24K')),
              oldGold22kBuy: Value(_buyFor(profile, '22K')),
              oldGold18kBuy: Value(_buyFor(profile, '18K')),
              source: const Value('Manual Rate Master'),
            ),
          );
      return;
    }

    if (profile.metal == MetalRateMetal.silver) {
      await _db.into(_db.dailyRates).insertOnConflictUpdate(
            DailyRatesCompanion(
              rateDate: Value(rateDate),
              silverJewellery: Value(_rateFor(profile, '925')),
              silverIdols: Value(_rateFor(profile, '999')),
              oldSilverBuy: Value(_buyFor(profile, '999')),
              source: const Value('Manual Rate Master'),
            ),
          );
    }
  }

  String _rateFor(MetalRateProfile profile, String label) {
    final plan = _planFor(profile, label);
    return (plan?.manualDisplayRatePer10g ?? 0).round().toString();
  }

  String _buyFor(MetalRateProfile profile, String label) {
    final plan = _planFor(profile, label);
    return (plan?.buyRatePer10g ?? 0).round().toString();
  }

  MetalRatePurityPlan? _planFor(MetalRateProfile profile, String label) {
    final key = label.toUpperCase().replaceAll('KT', 'K');
    for (final plan in profile.purityPlans) {
      if (plan.label.toUpperCase().replaceAll('KT', 'K') == key) {
        return plan;
      }
    }
    return null;
  }
}
