import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'backup_archive_service.dart';
import 'backup_locations.dart';

class BackupReferenceRelocator {
  BackupReferenceRelocator(
      BackupLocations locations, Map<String, dynamic> roots,
      [Map<String, dynamic> external = const {}])
      : _paths = {
          for (final resource
              in locations.resources.where((r) => !r.isDatabase))
            roots[resource.id] as String: resource.path
        },
        _external = {
          for (final item in external.entries)
            item.key: p.join(
                locations.resources
                    .firstWhere((resource) => resource.id == 'external_media')
                    .path,
                item.value as String)
        };
  final Map<String, String> _paths;
  final Map<String, String> _external;

  String _path(String value) {
    if (_external.containsKey(value)) return _external[value]!;
    for (final mapping in _paths.entries) {
      if (p.equals(mapping.key, mapping.value)) continue;
      if (p.equals(mapping.key, value)) return mapping.value;
      if (p.isAbsolute(value) && p.isWithin(mapping.key, value)) {
        return p.join(mapping.value, p.relative(value, from: mapping.key));
      }
    }
    return value;
  }

  Object relocatePreference(Object value) {
    if (value is String) {
      final changed = _path(value);
      if (changed != value) return changed;
      if (value.startsWith('{') || value.startsWith('[')) {
        try {
          final decoded = jsonDecode(value);
          var relocated = false;
          final result = _json(decoded, () => relocated = true);
          return relocated ? jsonEncode(result) : value;
        } on FormatException {
          return value;
        }
      }
    }
    if (value is List) {
      return value.map((item) => relocatePreference(item as Object)).toList();
    }
    return value;
  }

  Object? _json(Object? value, void Function() onChange) => switch (value) {
        String value => _relocatePath(value, onChange),
        Map value =>
          value.map((key, value) => MapEntry(key, _json(value, onChange))),
        List value => value.map((item) => _json(item, onChange)).toList(),
        _ => value,
      };

  String _relocatePath(String value, void Function() onChange) {
    final result = _path(value);
    if (result != value) onChange();
    return result;
  }

  String _relocateColumnValue(String column, String value) {
    final direct = _path(value);
    if (direct != value) return direct;
    if (!RegExp('path|file|photo|logo|signature|document|attachment|image|json',
            caseSensitive: false)
        .hasMatch(column)) {
      return value;
    }
    if (!value.startsWith('{') && !value.startsWith('[')) return value;
    try {
      var relocated = false;
      final result = _json(jsonDecode(value), () => relocated = true);
      return relocated ? jsonEncode(result) : value;
    } on FormatException {
      return value;
    }
  }

  void relocateDatabase(File file) {
    if (_external.isEmpty &&
        _paths.entries.every((entry) => p.equals(entry.key, entry.value))) {
      return;
    }
    final db = sqlite3.open(file.path);
    try {
      db.execute('BEGIN IMMEDIATE');
      final tables = db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      for (final table in tables) {
        final tableName = table['name'] as String;
        final columns = db
            .select('PRAGMA table_info(${_quote(tableName)})')
            .where((column) =>
                (column['type'] as String).toUpperCase().contains('TEXT'))
            .map((column) => column['name'] as String)
            .toList();
        if (columns.isEmpty) continue;
        // Plain path columns are rebased; financial snapshots and audit JSON
        // remain byte-for-byte intact.
        int? cursor;
        while (true) {
          final rows = db.select(
              'SELECT rowid AS "__restore_rowid", ${columns.map(_quote).join(',')} FROM ${_quote(tableName)} '
              '${cursor == null ? '' : 'WHERE rowid > ?'} ORDER BY rowid LIMIT 500',
              cursor == null ? [] : [cursor]);
          if (rows.isEmpty) break;
          for (final row in rows) {
            for (final column in columns) {
              final value = row[column];
              if (value is! String) continue;
              final updated = _relocateColumnValue(column, value);
              if (updated != value) {
                db.execute(
                    'UPDATE ${_quote(tableName)} SET ${_quote(column)}=? WHERE rowid=?',
                    [updated, row['__restore_rowid']]);
              }
            }
          }
          cursor = rows.last['__restore_rowid'] as int;
        }
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    } finally {
      db.dispose();
    }
  }

  Future<void> relocate(
      BackupLocations locations, VerifiedBackup backup) async {
    for (final resource in locations.resources.where((r) => r.isDatabase)) {
      relocateDatabase(File(backup.resourcePath(resource)));
    }
  }

  String _quote(String value) => '"${value.replaceAll('"', '""')}"';
}
