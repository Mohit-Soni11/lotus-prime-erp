import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_session_closure_repository.dart';
import 'package:lotus_erp/repositories/reports/day_book_balance_verification_repository.dart';
import 'package:lotus_erp/models/setting/metal_rate/metal_rate_model.dart';
import 'business_day_activity_repository.dart';

/// Records business dates opened by this installation. A counter-session close
/// ends one signed-in session; only legacy/finalised finance-day closures lock
/// a historical date permanently.
class BusinessDayRepository {
  final AppDatabase db;
  const BusinessDayRepository(this.db);

  static String key(DateTime day) => DateFormat('yyyyMMdd').format(day);
  static DateTime date(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<DateTime> activeDay(DateTime now) async {
    final pending = await pendingDays(now);
    return pending.isEmpty ? date(now) : pending.first;
  }

  Future<void> _recordToday(DateTime now) async {
    await db
        .customStatement('''CREATE TABLE IF NOT EXISTS business_day_sessions (
      day_key TEXT PRIMARY KEY,
      day_date TEXT NOT NULL,
      opened_at INTEGER NOT NULL
    )''');
    await db.transaction(() async {
      final today = date(now);
      if (!await isClosed(today)) {
        await db.customStatement('''INSERT OR IGNORE INTO business_day_sessions
          (day_key, day_date, opened_at) VALUES (?, ?, ?)''',
            [key(today), today.toIso8601String(), now.millisecondsSinceEpoch]);
      }
    });
  }

  Future<List<DateTime>> pendingDays(DateTime now) async {
    await _recordToday(now);
    final rows = await db.customSelect('''
      SELECT s.day_date FROM business_day_sessions s
      LEFT JOIN finance_day_closures c ON c.day_key = s.day_key
      WHERE c.day_key IS NULL ORDER BY s.day_key
    ''').get();
    final today = date(now);
    final activity = BusinessDayActivityRepository(db);
    final sessionClosures = FinanceSessionClosureRepository(db);
    final pending = <DateTime>[];
    for (final row in rows) {
      final day = DateTime.parse(row.read<String>('day_date'));
      final needsHistoricalClose = day.isBefore(today) &&
          await activity.hasActivity(day) &&
          !await sessionClosures.hasSessionClose(day);
      if (!day.isBefore(today) || needsHistoricalClose) {
        pending.add(day);
      }
    }
    return pending;
  }

  Future<bool> isClosed(DateTime day) =>
      FinanceDayClosureRepository(db).isClosed(day);

  /// A version lets the exit flow prove that the close action which it opened
  /// produced new evidence, rather than trusting a previously saved snapshot.
  Future<int> closingVersion(DateTime day) async {
    final legacyClosed = await isClosed(day);
    final sessions =
        await FinanceSessionClosureRepository(db).sessionCount(day);
    return sessions + (legacyClosed ? 1 : 0);
  }

  Future<bool> hasSessionClose(DateTime day) =>
      FinanceSessionClosureRepository(db).hasSessionClose(day);

  Future<bool> openingVerified(DateTime day) async =>
      await DayBookBalanceVerificationRepository(db).fetch(day) != null;

  Future<void> requestClosing(DateTime day) async {
    await db.customStatement(
        '''CREATE TABLE IF NOT EXISTS business_day_exit_requests (
      day_key TEXT PRIMARY KEY,
      requested_at INTEGER NOT NULL
    )''');
    await db.customStatement('''INSERT OR IGNORE INTO business_day_exit_requests
      (day_key, requested_at) VALUES (?, ?)''',
        [key(day), DateTime.now().millisecondsSinceEpoch]);
  }

  Future<bool> closingRequested(DateTime day) async {
    final table = await db
        .customSelect(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'business_day_exit_requests'")
        .getSingleOrNull();
    if (table == null) return false;
    return await db.customSelect(
          'SELECT 1 FROM business_day_exit_requests WHERE day_key = ?',
          variables: [Variable.withString(key(day))],
        ).getSingleOrNull() !=
        null;
  }

  Future<void> completeClosingRequest(DateTime day) async {
    final table = await db
        .customSelect(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'business_day_exit_requests'")
        .getSingleOrNull();
    if (table == null) return;
    await db.customStatement(
      'DELETE FROM business_day_exit_requests WHERE day_key = ?',
      [key(day)],
    );
  }

  Future<List<String>> pendingRateMetals(DateTime day) async {
    final start = date(day);
    final end = DateTime(start.year, start.month, start.day + 1);
    // Gold and Silver are the daily counter metals. Other metals become
    // required when the shop has stock or has explicitly maintained a rate.
    final metals = {'gold', 'silver'};
    final configured = await db.customSelect('''
      SELECT DISTINCT LOWER(TRIM(metal_type)) AS metal FROM stock_items
      WHERE is_active = 1
      UNION SELECT metal_key AS metal FROM metal_rate_revisions
      WHERE COALESCE(change_reason, '') NOT IN
        ('Migrated to rate ledger', 'Restored default profile')
    ''').get();
    for (final row in configured) {
      final metal = row.read<String>('metal');
      if (const {'gold', 'silver', 'diamond', 'platinum'}.contains(metal)) {
        metals.add(metal);
      }
    }
    final saved = await db.customSelect('''
      SELECT metal_key, profile_json, change_reason FROM metal_rate_revisions
      WHERE effective_at >= ? AND effective_at < ?
      ORDER BY effective_at DESC, revision DESC
    ''', variables: [
      Variable.withDateTime(start),
      Variable.withDateTime(end),
    ]).get();
    final seen = <String>{};
    final confirmed = <String>{};
    for (final row in saved) {
      final metal = row.read<String>('metal_key');
      if (!seen.add(metal)) continue;
      if (const {'Migrated to rate ledger', 'Restored default profile'}
          .contains(row.readNullable<String>('change_reason'))) {
        continue;
      }
      try {
        final profile = MetalRateProfile.fromJson(
          Map<String, dynamic>.from(
              jsonDecode(row.read<String>('profile_json')) as Map),
        );
        if (profile.primaryShopRatePer10g.isFinite &&
            profile.primaryShopRatePer10g > 0) {
          confirmed.add(metal);
        }
      } on FormatException {
        // An unreadable profile cannot confirm a usable daily counter rate.
      }
    }
    return metals.difference(confirmed).toList()..sort();
  }
}
