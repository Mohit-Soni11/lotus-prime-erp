import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'backup_locations.dart';
import 'backup_file_safety.dart';

abstract final class BackupDatabaseSnapshot {
  static Future<void> capture(
      BackupLocations locations, Directory workspace) async {
    final guards = <Database>[];
    try {
      for (final resource in locations.resources.where((r) => r.isDatabase)) {
        await requireNoLinks(resource.path);
        if (!await File(resource.path).exists()) {
          throw StateError(
              'Complete account and shop setup before creating a backup.');
        }
        final guard = sqlite3.open(resource.path);
        guards.add(guard);
        guard.execute('PRAGMA busy_timeout=5000');
        guard.execute('BEGIN IMMEDIATE');
      }
      for (final resource in locations.resources.where((r) => r.isDatabase)) {
        final source = sqlite3.open(resource.path, mode: OpenMode.readOnly);
        Database? destination;
        try {
          final target = File(p.join(
              workspace.path, 'payload', resource.id, 'database.sqlite'));
          await target.parent.create(recursive: true);
          destination = sqlite3.open(target.path);
          verify(source, resource);
          await source.backup(destination).drain<void>();
          destination.execute('PRAGMA journal_mode=DELETE');
        } finally {
          destination?.dispose();
          source.dispose();
        }
      }
    } finally {
      for (final guard in guards.reversed) {
        try {
          guard.execute('ROLLBACK');
        } on SqliteException {
          // A failed lock acquisition has no transaction to roll back.
        } finally {
          guard.dispose();
        }
      }
    }
  }

  static int version(File file) {
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      return db.select('PRAGMA user_version').single.values.single as int;
    } finally {
      db.dispose();
    }
  }

  static void verify(Database database, BackupResource resource) {
    if (database.select('PRAGMA integrity_check').single.values.single !=
        'ok') {
      throw const FormatException('A database failed its integrity check.');
    }
    final version =
        database.select('PRAGMA user_version').single.values.single as int;
    if (version < 1 || version > resource.schemaVersion!) {
      throw StateError(
          'This backup requires a newer version of Lotus ERP. Update the software first.');
    }
    final table = resource.id == 'business' ? 'bills' : 'local_owner_account';
    if (database.select('SELECT 1 FROM sqlite_master WHERE type=? AND name=?',
        ['table', table]).isEmpty) {
      throw const FormatException(
          'The database does not contain the expected Lotus ERP records.');
    }
  }
}
