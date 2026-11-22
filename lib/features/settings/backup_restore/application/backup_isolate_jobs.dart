import 'dart:io';

import '../data/backup_archive_service.dart';
import '../data/backup_locations.dart';
import '../data/backup_restore_service.dart';
import '../data/backup_store.dart';
import '../domain/backup_record.dart';

// Isolate jobs carry only data. Bound methods avoid capturing the coordinator,
// its UI listeners, and platform services through a nested closure.
class BackupJobLocations {
  BackupJobLocations(BackupLocations locations)
      : rootPath = locations.root.path,
        resources = [
          for (final resource in locations.resources)
            (resource.id, resource.path, resource.schemaVersion),
        ];

  final String rootPath;
  final List<(String, String, int?)> resources;

  BackupLocations materialize() => BackupLocations(
        root: Directory(rootPath),
        resources: [
          for (final (id, path, schemaVersion) in resources)
            BackupResource(id, path, schemaVersion: schemaVersion),
        ],
      );
}

class CreateLocalBackupJob {
  CreateLocalBackupJob(BackupLocations locations, this.folder, this.preferences)
      : locations = BackupJobLocations(locations);

  final BackupJobLocations locations;
  final String folder;
  final Map<String, Object> preferences;

  Future<BackupRecord> call() =>
      BackupArchiveService(locations.materialize()).create(folder, preferences);
}

class VerifyLocalBackupJob {
  VerifyLocalBackupJob(BackupLocations locations, this.filePath)
      : locations = BackupJobLocations(locations);

  final BackupJobLocations locations;
  final String filePath;

  Future<VerifiedBackup> call() =>
      BackupArchiveService(locations.materialize()).verify(File(filePath));
}

class PrepareLocalRestoreJob {
  PrepareLocalRestoreJob(BackupLocations locations, this.filePath)
      : locations = BackupJobLocations(locations);

  final BackupJobLocations locations;
  final String filePath;

  Future<void> call() => BackupRestoreService(
        locations.materialize(),
        SharedBusinessPreferences(),
        clearSession: () async {},
      ).prepare(File(filePath));
}
