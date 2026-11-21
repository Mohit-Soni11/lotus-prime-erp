import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../../../config/app_config.dart';
import '../domain/backup_record.dart';
import 'backup_file_safety.dart';
import 'backup_locations.dart';
import 'backup_store.dart';
import 'backup_media_inventory.dart';
import 'backup_archive_validator.dart';
import 'backup_database_snapshot.dart';
export 'backup_archive_validator.dart' show VerifiedBackup;

class BackupArchiveService {
  const BackupArchiveService(this.locations);
  final BackupLocations locations;
  static const maxFiles = BackupArchiveValidator.maxFiles;
  static const maxBytes = BackupArchiveValidator.maxBytes;

  Future<BackupRecord> create(
      String folder, Map<String, Object> preferences) async {
    locations.validateDestination(folder);
    await requireNoLinks(folder);
    final id = const Uuid().v4();
    final at = DateTime.now().toUtc();
    final workspace = Directory(p.join(locations.work.path, 'create-$id'));
    final name =
        'Lotus-ERP-${at.toIso8601String().replaceAll(':', '-')}-$id.lotusbackup';
    final output = File(p.join(folder, name));
    final pending = File('${output.path}.pending');
    await workspace.create(recursive: true);
    try {
      await BackupDatabaseSnapshot.capture(locations, workspace);
      for (final resource in locations.resources.where((r) => !r.isDatabase)) {
        await copyBackupTree(
            resource.path, p.join(workspace.path, 'payload', resource.id));
      }
      await writeBackupJson(
          File(p.join(workspace.path, 'preferences.json')), preferences);
      final media = BackupMediaInventory();
      await media.capture(locations, workspace, preferences);
      final files = <Map<String, dynamic>>[];
      var total = 0;
      await for (final entity
          in workspace.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final name = p
            .relative(entity.path, from: workspace.path)
            .replaceAll(p.separator, '/');
        validateArchivePath(name);
        final size = await entity.length();
        total += size;
        if (total > maxBytes || files.length >= maxFiles) {
          throw StateError('The backup exceeds the supported archive size.');
        }
        files.add({
          'path': name,
          'size': size,
          'sha256': await backupFileHash(entity)
        });
      }
      final manifest = {
        'format': 'lotus-erp-backup',
        'version': 1,
        'id': id,
        'createdAt': at.toIso8601String(),
        'appVersion': AppConfig.semanticVersion,
        'externalMedia': media.external,
        'missingMedia': media.missing.toList(),
        'roots': {
          for (final resource in locations.resources) resource.id: resource.path
        },
        'schemas': {
          for (final resource in locations.resources.where((r) => r.isDatabase))
            resource.id: BackupDatabaseSnapshot.version(File(p.join(
                workspace.path, 'payload', resource.id, 'database.sqlite')))
        },
        'files': files
      };
      await writeBackupJson(
          File(p.join(workspace.path, 'manifest.json')), manifest);
      await output.parent.create(recursive: true);
      final outputStream = OutputFileStream(pending.path);
      final encoder = ZipFileEncoder();
      try {
        encoder.createWithStream(outputStream);
        await encoder.addDirectory(workspace,
            includeDirName: false, followLinks: false);
        await encoder.close();
      } finally {
        await outputStream.close();
      }
      // Read the completed archive back before publishing it as a usable backup.
      final checked = await verify(pending);
      await deleteBackupEntity(checked.directory.path);
      await pending.rename(output.path);
      return BackupRecord(
          id: id,
          name: name,
          createdAt: at,
          size: await output.length(),
          sha256: await backupFileHash(output),
          missingMediaCount: media.missing.length,
          localPath: output.path);
    } finally {
      await deleteBackupEntity(workspace.path);
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<VerifiedBackup> verify(File file) =>
      BackupArchiveValidator(locations).verify(file);
}
