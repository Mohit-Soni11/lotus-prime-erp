import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Creates an SQLite-consistent copy before Drift applies a version upgrade.
class DatabaseMigrationBackup {
  const DatabaseMigrationBackup._();

  static Future<File?> createIfNeeded(
      File databaseFile, int targetVersion) async {
    if (!await databaseFile.exists()) return null;
    final source = sqlite3.open(databaseFile.path, mode: OpenMode.readOnly);
    File? pending;
    try {
      final sourceVersion = _version(source);
      if (sourceVersion >= targetVersion) return null;
      _verify(source);

      final suffix = DateTime.now().toUtc().microsecondsSinceEpoch;
      final backup = File(
          '${databaseFile.path}.before-v$targetVersion.$suffix.backup.sqlite');
      pending = File('${backup.path}.pending');
      final destination = sqlite3.open(pending.path);
      try {
        await source.backup(destination).drain<void>();
      } finally {
        destination.dispose();
      }

      final verifyCopy = sqlite3.open(pending.path, mode: OpenMode.readOnly);
      try {
        _verify(verifyCopy);
        if (_version(verifyCopy) != sourceVersion) {
          throw StateError('Migration backup schema version does not match.');
        }
      } finally {
        verifyCopy.dispose();
      }
      await pending.rename(backup.path);
      pending = null;
      return backup;
    } finally {
      source.dispose();
      if (pending != null && await pending.exists()) {
        await pending.delete();
      }
    }
  }

  static int _version(Database database) =>
      database.select('PRAGMA user_version').single['user_version'] as int;

  static void _verify(Database database) {
    final result =
        database.select('PRAGMA integrity_check').single.values.single;
    if (result != 'ok') {
      throw StateError('Database integrity check failed: $result');
    }
  }
}
