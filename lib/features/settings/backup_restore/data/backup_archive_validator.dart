import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import 'backup_database_snapshot.dart';
import 'backup_file_safety.dart';
import 'backup_locations.dart';
import 'backup_store.dart';
import 'backup_zip_safety.dart';

class VerifiedBackup {
  const VerifiedBackup(this.directory, this.manifest);
  final Directory directory;
  final Map<String, dynamic> manifest;
  String get id => manifest['id'] as String;
  DateTime get createdAt => DateTime.parse(manifest['createdAt'] as String);
  int get fileCount => (manifest['files'] as List).length;
  String resourcePath(BackupResource resource) => p.joinAll([
        directory.path,
        'payload',
        resource.id,
        if (resource.isDatabase) 'database.sqlite'
      ]);
}

class BackupArchiveValidator {
  const BackupArchiveValidator(this.locations);
  final BackupLocations locations;
  static const maxFiles = 200000;
  static const maxBytes = 50 * 1024 * 1024 * 1024;

  Future<VerifiedBackup> verify(File file) async {
    if (!await file.exists()) {
      throw StateError('The selected backup file is missing.');
    }
    if (await file.length() > maxBytes) {
      throw const FormatException('The backup file is too large.');
    }
    final workspace =
        Directory(p.join(locations.work.path, 'verify-${const Uuid().v4()}'));
    await workspace.create(recursive: true);
    final input = InputFileStream(file.path);
    try {
      await BackupZipSafety.preflight(file,
          maxFiles: maxFiles, maxBytes: maxBytes);
      BackupZipSafety.validateDirectory(input,
          maxFiles: maxFiles, maxBytes: maxBytes);
      final archive = ZipDecoder().decodeStream(input);
      final manifestEntry = archive.findFile('manifest.json');
      if (manifestEntry == null ||
          !manifestEntry.isFile ||
          manifestEntry.size > 16 * 1024 * 1024) {
        throw const FormatException('This is not a Lotus ERP backup.');
      }
      final manifestFile = File(p.join(workspace.path, 'manifest.json'));
      await BackupZipSafety.extract(
          manifestEntry, manifestFile, 16 * 1024 * 1024);
      final manifest =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      if (manifest['format'] != 'lotus-erp-backup' ||
          manifest['version'] != 1 ||
          !RegExp(r'^[a-f0-9-]{36}$')
              .hasMatch(manifest['id'] as String? ?? '')) {
        throw const FormatException('Unsupported Lotus ERP backup format.');
      }
      DateTime.parse(manifest['createdAt'] as String);
      final roots = Map<String, dynamic>.from(manifest['roots'] as Map);
      if (roots.keys
              .toSet()
              .difference(locations.resources.map((r) => r.id).toSet())
              .isNotEmpty ||
          locations.resources.any((r) => roots[r.id] is! String)) {
        throw const FormatException(
            'The backup has an unsupported resource inventory.');
      }
      if (roots.values.any((value) =>
          value is! String ||
          !p.isAbsolute(value) ||
          p.dirname(value) == value)) {
        throw const FormatException(
            'The backup contains invalid original file locations.');
      }
      final missingMedia = manifest['missingMedia'];
      if (missingMedia != null &&
          (missingMedia is! List ||
              !missingMedia.every((value) => value is String))) {
        throw const FormatException('The backup media inventory is invalid.');
      }
      final missingIssuedDocuments = manifest['missingIssuedDocuments'];
      if (missingIssuedDocuments != null &&
          (missingIssuedDocuments is! List ||
              !missingIssuedDocuments.every((value) => value is String))) {
        throw const FormatException(
            'The backup issued document inventory is invalid.');
      }
      final declared = (manifest['files'] as List)
          .cast<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (declared.length > maxFiles) {
        throw const FormatException('Too many files in backup.');
      }
      final files = <String, Map<String, dynamic>>{};
      final names = <String>{};
      var total = 0;
      for (final item in declared) {
        final name = item['path'] as String;
        validateArchivePath(name);
        final parts = name.split('/');
        if (name != 'preferences.json' &&
            (parts.length < 3 ||
                parts.first != 'payload' ||
                !roots.containsKey(parts[1]))) {
          throw const FormatException('Unexpected content in backup.');
        }
        final size = (item['size'] as num).toInt();
        total += size;
        if (size < 0 ||
            (name == 'preferences.json' && size > 16 * 1024 * 1024) ||
            total > maxBytes ||
            !names.add(name.toLowerCase()) ||
            !RegExp(r'^[a-f0-9]{64}$')
                .hasMatch(item['sha256'] as String? ?? '')) {
          throw const FormatException('Invalid backup file inventory.');
        }
        files[name] = item;
      }
      final seen = <String>{};
      for (final entry in archive) {
        final name = entry.name;
        if (!entry.isFile) {
          validateArchivePath(
              name.endsWith('/') ? name.substring(0, name.length - 1) : name);
          if (entry.isSymbolicLink) {
            throw const FormatException('Backup links are not supported.');
          }
          continue;
        }
        validateArchivePath(name);
        if (!seen.add(name.toLowerCase()) || entry.isSymbolicLink) {
          throw const FormatException('Duplicate or linked backup entry.');
        }
        if (name == 'manifest.json') continue;
        final expected = files[name];
        if (expected == null || entry.size != expected['size']) {
          throw const FormatException(
              'Backup contents do not match the inventory.');
        }
        final target = File(p.joinAll([workspace.path, ...name.split('/')]));
        await target.parent.create(recursive: true);
        await BackupZipSafety.extract(entry, target, expected['size'] as int);
        if (await target.length() != expected['size'] ||
            await backupFileHash(target) != expected['sha256']) {
          throw const FormatException(
              'Backup verification failed. A file is damaged or incomplete.');
        }
      }
      if (files.keys.any((name) => !seen.contains(name.toLowerCase())) ||
          !files.containsKey('preferences.json')) {
        throw const FormatException('The backup is incomplete.');
      }
      final verified = VerifiedBackup(workspace, manifest);
      for (final resource in locations.resources) {
        if (resource.isDatabase) {
          final database = File(verified.resourcePath(resource));
          if (!await database.exists()) {
            throw const FormatException('A required database is missing.');
          }
          final db = sqlite3.open(database.path, mode: OpenMode.readOnly);
          try {
            BackupDatabaseSnapshot.verify(db, resource);
            final schema = (manifest['schemas'] as Map)[resource.id];
            if (schema !=
                db.select('PRAGMA user_version').single.values.single) {
              throw const FormatException(
                  'The backup schema inventory is invalid.');
            }
          } finally {
            db.dispose();
          }
        } else {
          await Directory(verified.resourcePath(resource))
              .create(recursive: true);
        }
      }
      final external =
          Map<String, dynamic>.from(manifest['externalMedia'] as Map? ?? {});
      for (final item in external.entries) {
        final name = item.value;
        if (!p.isAbsolute(item.key) ||
            name is! String ||
            name != p.basename(name)) {
          throw const FormatException('Invalid external document inventory.');
        }
        validateArchivePath('payload/external_media/$name');
        if (!files.containsKey('payload/external_media/$name')) {
          throw const FormatException(
              'An external document is missing from the backup.');
        }
      }
      final preferences = jsonDecode(
          await File(p.join(workspace.path, 'preferences.json'))
              .readAsString());
      if (preferences is! Map<String, dynamic> ||
          preferences.values.any((v) =>
              v is! String &&
              v is! bool &&
              v is! num &&
              !(v is List && v.every((item) => item is String)))) {
        throw const FormatException('The backup preferences are invalid.');
      }
      await writeBackupJson(
          File(p.join(workspace.path, 'manifest.json')), manifest);
      return verified;
    } catch (_) {
      await deleteBackupEntity(workspace.path);
      rethrow;
    } finally {
      await input.close();
    }
  }
}
