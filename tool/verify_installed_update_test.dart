import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/database/local_database/shop_database_schema.dart';

/// Opt-in release check. Opens installed databases read-only; all migrations
/// run on SQLite-consistent copies outside the source repository.
void main() {
  test('installed data remains intact after opening with the update', () async {
    final local = Platform.environment['LOCALAPPDATA'];
    if (local == null) throw StateError('Windows LOCALAPPDATA is required.');
    final sourceRoot = p.join(local, 'Lotus ERP', 'Data');
    final snapshotRoot = Directory(p.join(
        local,
        'Lotus ERP',
        'Backups',
        'verification',
        DateTime.now().toUtc().microsecondsSinceEpoch.toString()));
    await snapshotRoot.create(recursive: true);
    sqfliteFfiInit();
    final results = <Map<String, Object>>[];
    for (final name in ['lotus_erp_pro.sqlite', 'erp_master_db.db']) {
      final original = File(p.join(sourceRoot, name));
      if (!await original.exists()) {
        throw StateError('Installed database missing: $name');
      }
      final copy = File(p.join(snapshotRoot.path, name));
      final source =
          sqlite.sqlite3.open(original.path, mode: sqlite.OpenMode.readOnly);
      try {
        final destination = sqlite.sqlite3.open(copy.path);
        try {
          await source.backup(destination).drain<void>();
        } finally {
          destination.dispose();
        }
      } finally {
        source.dispose();
      }
      final beforeDb =
          sqlite.sqlite3.open(copy.path, mode: sqlite.OpenMode.readOnly);
      late Map<String, _TableSnapshot> before;
      late int oldVersion;
      try {
        _checkIntegrity(beforeDb);
        oldVersion = beforeDb
            .select('PRAGMA user_version')
            .single['user_version'] as int;
        before = _snapshot(beforeDb);
      } finally {
        beforeDb.dispose();
      }
      if (name == 'lotus_erp_pro.sqlite') {
        final upgraded = AppDatabase.forTesting(NativeDatabase(copy));
        try {
          await upgraded.customSelect('SELECT 1').get();
        } finally {
          await upgraded.close();
        }
      } else {
        final upgraded = await databaseFactoryFfi.openDatabase(copy.path,
            options: OpenDatabaseOptions(
                version: ShopDatabaseSchema.currentVersion,
                singleInstance: false,
                onConfigure: ShopDatabaseSchema.configure,
                onCreate: ShopDatabaseSchema.create,
                onUpgrade: ShopDatabaseSchema.upgrade));
        await upgraded.close();
      }
      final afterDb =
          sqlite.sqlite3.open(copy.path, mode: sqlite.OpenMode.readOnly);
      try {
        _checkIntegrity(afterDb);
        _verifyPreserved(afterDb, before);
        results.add({
          'database': name,
          'sourceVersion': oldVersion,
          'updatedVersion': afterDb
              .select('PRAGMA user_version')
              .single['user_version'] as int,
          'verifiedTables': before.length,
          'existingRecordsPreserved': true
        });
      } finally {
        afterDb.dispose();
      }
    }
    await File(p.join(snapshotRoot.path, 'compatibility-report.json'))
        .writeAsString(const JsonEncoder.withIndent('  ').convert(results));
    // Only a backup location is printed; no account or transaction data.
    stdout.writeln('Verified database copies: ${snapshotRoot.path}');
  }, skip: !const bool.fromEnvironment('LOTUS_VERIFY_INSTALLED_COPY'));
}

class _TableSnapshot {
  final List<String> columns;
  final String digest;
  final int count;
  const _TableSnapshot(this.columns, this.digest, this.count);
}

String _quote(String value) => '"${value.replaceAll('"', '""')}"';

Map<String, _TableSnapshot> _snapshot(sqlite.Database db) => {
      for (final row in db.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'"))
        row['name'] as String: _tableSnapshot(db, row['name'] as String),
    };

_TableSnapshot _tableSnapshot(sqlite.Database db, String name,
    [List<String>? columns]) {
  final selected = columns ??
      db
          .select('PRAGMA table_info(${_quote(name)})')
          .map((row) => row['name'] as String)
          .toList();
  final rows = db
      .select('SELECT ${selected.map(_quote).join(', ')} FROM ${_quote(name)}')
      .map((row) => jsonEncode([for (final column in selected) row[column]]))
      .toList()
    ..sort();
  return _TableSnapshot(selected,
      sha256.convert(utf8.encode(jsonEncode(rows))).toString(), rows.length);
}

void _checkIntegrity(sqlite.Database db) {
  if (db.select('PRAGMA integrity_check').single.values.single != 'ok') {
    throw StateError('A database failed its integrity check.');
  }
}

void _verifyPreserved(sqlite.Database db, Map<String, _TableSnapshot> before) {
  final tables = db
      .select("SELECT name FROM sqlite_master WHERE type = 'table'")
      .map((row) => row['name'] as String)
      .toSet();
  for (final entry in before.entries) {
    if (!tables.contains(entry.key)) {
      if (entry.value.count > 0) {
        throw StateError('A populated table was removed: ${entry.key}');
      }
      continue;
    }
    final after = _tableSnapshot(db, entry.key, entry.value.columns);
    if (after.digest != entry.value.digest) {
      throw StateError(
          'Existing records changed during migration: ${entry.key}');
    }
  }
}
