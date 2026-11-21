import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'backup_file_safety.dart';
import 'backup_locations.dart';

/// Includes legacy attachments that were originally saved outside managed folders.
class BackupMediaInventory {
  final external = <String, String>{};
  final missing = <String>{};
  final _references = <String>{};

  Future<void> capture(BackupLocations locations, Directory stage,
      Map<String, Object> preferences) async {
    _collect(preferences);
    for (final resource
        in locations.resources.where((resource) => resource.isDatabase)) {
      final db = sqlite3.open(
          p.join(stage.path, 'payload', resource.id, 'database.sqlite'),
          mode: OpenMode.readOnly);
      try {
        for (final table in db.select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) {
          final name = table['name'] as String;
          final columns = db
              .select('PRAGMA table_info(${_quote(name)})')
              .where((column) =>
                  (column['type'] as String).toUpperCase().contains('TEXT') &&
                  RegExp('path|file|photo|logo|signature|document|attachment|image|json',
                          caseSensitive: false)
                      .hasMatch(column['name'] as String))
              .map((column) => column['name'] as String)
              .toList();
          if (columns.isEmpty) continue;
          int? cursor;
          while (true) {
            final rows = db.select(
                'SELECT rowid AS "__backup_rowid", ${columns.map(_quote).join(',')} FROM ${_quote(name)} '
                '${cursor == null ? '' : 'WHERE rowid > ?'} ORDER BY rowid LIMIT 500',
                cursor == null ? [] : [cursor]);
            if (rows.isEmpty) break;
            for (final row in rows) {
              for (final column in columns) {
                _collect(row[column]);
              }
            }
            cursor = rows.last['__backup_rowid'] as int;
          }
        }
      } finally {
        db.dispose();
      }
    }
    final externalResource = locations.resources
        .where((resource) => resource.id == 'external_media');
    for (final reference in _references) {
      final type = await FileSystemEntity.type(reference, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        if (const {
          '.jpg',
          '.jpeg',
          '.png',
          '.webp',
          '.gif',
          '.pdf',
          '.bmp',
          '.heic',
          '.tiff'
        }.contains(p.extension(reference).toLowerCase())) {
          missing.add(reference);
        }
        continue;
      }
      if (type == FileSystemEntityType.directory) continue;
      if (locations.resources.any((resource) =>
          !resource.isDatabase &&
          (p.equals(resource.path, reference) ||
              p.isWithin(resource.path, reference)))) {
        continue;
      }
      if (externalResource.isEmpty) {
        throw StateError('External media storage is not configured.');
      }
      await requireNoLinks(reference);
      final identity = Platform.isWindows
          ? p.normalize(reference).toLowerCase()
          : p.normalize(reference);
      final fileName =
          '${sha256.convert(utf8.encode(identity))}${p.extension(reference).toLowerCase()}';
      validateArchivePath('payload/external_media/$fileName');
      await copyBackupTree(
          reference, p.join(stage.path, 'payload', 'external_media', fileName));
      external[reference] = fileName;
    }
  }

  void _collect(Object? value) {
    if (value is Map) {
      for (final item in value.values) {
        _collect(item);
      }
    } else if (value is List) {
      for (final item in value) {
        _collect(item);
      }
    } else if (value is String) {
      if (p.isAbsolute(value) &&
          !const {'.sqlite', '.db', '.exe', '.dll', '.lotusbackup'}
              .contains(p.extension(value).toLowerCase())) {
        _references.add(value);
      } else if (value.length < 8 * 1024 * 1024 &&
          (value.startsWith('{') || value.startsWith('['))) {
        try {
          _collect(jsonDecode(value));
        } on FormatException {
          /* A non-JSON text value has no nested file references. */
        }
      }
    }
  }

  String _quote(String value) => '"${value.replaceAll('"', '""')}"';
}
