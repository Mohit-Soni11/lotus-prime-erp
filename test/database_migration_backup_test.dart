import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/migrations/database_migration_backup.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('pre-upgrade backup is consistent with a live WAL database', () async {
    final directory = await Directory.systemTemp.createTemp('lotus-backup-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}shop.sqlite');
    final source = sqlite3.open(file.path);
    addTearDown(source.dispose);
    source.execute('PRAGMA journal_mode=WAL');
    source.execute('PRAGMA user_version=70');
    source
        .execute('CREATE TABLE invoices (id INTEGER PRIMARY KEY, amount REAL)');
    source.execute('INSERT INTO invoices (id, amount) VALUES (1, 125.50)');

    final backup = await DatabaseMigrationBackup.createIfNeeded(file, 71);
    expect(backup, isNotNull);
    expect(await backup!.exists(), isTrue);
    final copy = sqlite3.open(backup.path, mode: OpenMode.readOnly);
    try {
      expect(copy.select('PRAGMA user_version').single['user_version'], 70);
      expect(
          copy.select('SELECT amount FROM invoices').single['amount'], 125.5);
      expect(copy.select('PRAGMA integrity_check').single.values.single, 'ok');
    } finally {
      copy.dispose();
    }

    source.execute('PRAGMA user_version=71');
    expect(await DatabaseMigrationBackup.createIfNeeded(file, 71), isNull);

    final restored =
        File('${directory.path}${Platform.pathSeparator}restored.sqlite');
    await backup.copy(restored.path);
    final recovery = sqlite3.open(restored.path, mode: OpenMode.readOnly);
    try {
      expect(recovery.select('SELECT amount FROM invoices').single['amount'],
          125.5);
    } finally {
      recovery.dispose();
    }
  });

  test('corrupt database stops migration before a backup is accepted',
      () async {
    final directory = await Directory.systemTemp.createTemp('lotus-corrupt-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}bad.sqlite');
    await file.writeAsString('not a sqlite database');
    await expectLater(
      DatabaseMigrationBackup.createIfNeeded(file, 71),
      throwsA(isA<Exception>()),
    );
  });
}
