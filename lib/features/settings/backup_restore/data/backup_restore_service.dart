import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import 'backup_archive_service.dart';
import 'backup_file_safety.dart';
import 'backup_locations.dart';
import 'backup_reference_relocator.dart';
import 'backup_store.dart';

/// Restore is staged in the UI and committed only before application databases
/// open on the next launch. A durable journal permits recovery after power loss.
class BackupRestoreService {
  BackupRestoreService(this.locations, this.preferences,
      {required this.clearSession,
      Future<void> Function(String)? cleanupDelete})
      : cleanupDelete = cleanupDelete ?? deleteBackupEntity;
  final BackupLocations locations;
  final BusinessPreferences preferences;
  final Future<void> Function() clearSession;
  final Future<void> Function(String) cleanupDelete;
  File get pending => File(p.join(locations.root.path, 'restore-pending.json'));
  File get journal => File(p.join(locations.root.path, 'restore-journal.json'));
  File get lastResult => File(p.join(locations.root.path, 'last-restore.json'));
  File get cleanupPending =>
      File(p.join(locations.root.path, 'restore-cleanup-pending.json'));
  File get _package => File(
      p.join(locations.root.path, 'RestorePending', 'package.lotusbackup'));
  File get _originalPreferences => File(p.join(
      locations.root.path, 'RestorePending', 'original-preferences.json'));

  Future<void> prepare(File source) async {
    if (await pending.exists() || await journal.exists()) {
      throw StateError('A restore is already waiting for restart.');
    }
    await requireNoLinks(_package.parent.path);
    await _package.parent.create(recursive: true);
    final temporary = File('${_package.path}.pending');
    try {
      await source.copy(temporary.path);
      final verified = await BackupArchiveService(locations).verify(temporary);
      await deleteBackupEntity(verified.directory.path);
      await temporary.rename(_package.path);
      await writeBackupJson(pending,
          {'id': const Uuid().v4(), 'sha256': await backupFileHash(_package)});
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<bool> applyPending() async {
    await _retryCleanup();
    if (await journal.exists()) {
      final state = _read(await journal.readAsString());
      if (state['phase'] == 'committed') {
        await clearSession();
        if (await _cleanup(state)) {
          await _report(true, _cleanupWarning);
        }
        return true;
      }
      await _rollback(state);
      await _report(false,
          'An interrupted restore was rolled back. Your previous records were recovered.');
      return false;
    }
    if (!await pending.exists()) return false;
    VerifiedBackup? backup;
    Map<String, dynamic>? state;
    var committed = false;
    final temporaryResources = <String>[];
    try {
      final request = _read(await pending.readAsString());
      final id = request['id'] as String;
      _validateId(id);
      if (await backupFileHash(_package) != request['sha256']) {
        throw StateError('The staged backup changed before restart.');
      }
      backup = await BackupArchiveService(locations).verify(_package);
      final originalPreferences = await preferences.read();
      await writeBackupJson(_originalPreferences, originalPreferences);
      // This recovery package is completed and verified before any replacement.
      await BackupArchiveService(locations)
          .create(locations.recovery.path, originalPreferences);
      final relocator = BackupReferenceRelocator(
          locations,
          Map<String, dynamic>.from(backup.manifest['roots'] as Map),
          Map<String, dynamic>.from(
              backup.manifest['externalMedia'] as Map? ?? {}));
      await relocator.relocate(locations, backup);
      await _checkpointDatabases();
      final existed = <String, bool>{};
      for (final resource in locations.resources) {
        await requireNoLinks(resource.path);
        existed[resource.id] = await FileSystemEntity.type(resource.path) !=
            FileSystemEntityType.notFound;
        final next = _sibling(resource, id, 'new');
        if (await FileSystemEntity.type(next) !=
                FileSystemEntityType.notFound ||
            await FileSystemEntity.type(_sibling(resource, id, 'old')) !=
                FileSystemEntityType.notFound) {
          throw StateError('A recovery workspace already exists.');
        }
        temporaryResources.add(next);
        await copyBackupTree(backup.resourcePath(resource), next);
      }
      state = {'id': id, 'phase': 'applying', 'existed': existed};
      await writeBackupJson(journal, state);
      for (final resource in locations.resources) {
        if (existed[resource.id]!) {
          await renameBackupEntity(
              resource.path, _sibling(resource, id, 'old'));
        }
        await renameBackupEntity(_sibling(resource, id, 'new'), resource.path);
      }
      final rawPreferences = _read(
          await File(p.join(backup.directory.path, 'preferences.json'))
              .readAsString());
      await preferences.replace({
        for (final entry in rawPreferences.entries)
          entry.key: relocator.relocatePreference(entry.value as Object)
      });
      await clearSession();
      state['phase'] = 'committed';
      await writeBackupJson(journal, state);
      committed = true;
      await _report(true,
          'Backup restored successfully. Sign in with the account from the restored backup.');
      if (await _cleanup(state)) {
        await _report(true, _cleanupWarning);
      }
      return true;
    } catch (_) {
      if (committed) rethrow;
      if (state != null) {
        await _rollback(state);
      } else {
        if (await pending.exists()) await pending.delete();
      }
      await _report(false,
          'Restore could not be completed. Your previous records remain available.');
      rethrow;
    } finally {
      if (!committed && !await journal.exists()) {
        for (final path in temporaryResources) {
          await deleteBackupEntity(path);
        }
      }
      if (backup != null) await deleteBackupEntity(backup.directory.path);
    }
  }

  Future<void> _checkpointDatabases() async {
    for (final resource in locations.resources.where((r) => r.isDatabase)) {
      final db = sqlite3.open(resource.path);
      try {
        db.execute('PRAGMA busy_timeout=5000');
        final result = db.select('PRAGMA wal_checkpoint(TRUNCATE)').single;
        if ((result.values.first as int) != 0) {
          throw StateError(
              'Another application is using these records. Close it before restoring.');
        }
      } finally {
        db.dispose();
      }
      for (final suffix in ['-wal', '-shm', '-journal']) {
        await deleteBackupEntity('${resource.path}$suffix');
      }
    }
  }

  Future<void> _rollback(Map<String, dynamic> state) async {
    final id = state['id'] as String;
    _validateId(id);
    final existed = Map<String, dynamic>.from(state['existed'] as Map);
    if (locations.resources.any((r) => existed[r.id] is! bool)) {
      throw StateError('The recovery journal is incomplete.');
    }
    for (final resource in locations.resources.reversed) {
      final previous = _sibling(resource, id, 'old');
      final next = _sibling(resource, id, 'new');
      if (await FileSystemEntity.type(previous) !=
          FileSystemEntityType.notFound) {
        await deleteBackupEntity(resource.path);
        await renameBackupEntity(previous, resource.path);
      } else if (existed[resource.id] == false &&
          await FileSystemEntity.type(next) == FileSystemEntityType.notFound) {
        await deleteBackupEntity(resource.path);
      }
      await deleteBackupEntity(next);
    }
    if (await _originalPreferences.exists()) {
      final values = _read(await _originalPreferences.readAsString());
      await preferences
          .replace(values.map((key, value) => MapEntry(key, value as Object)));
    }
    if (await pending.exists()) await pending.delete();
    if (await journal.exists()) await journal.delete();
  }

  static const _cleanupWarning =
      'Backup restored successfully. Some previous files could not be removed from OneDrive. Your recovery backup is safe; cleanup will retry when Lotus ERP next opens.';

  Future<bool> _cleanup(Map<String, dynamic> state) async {
    final id = state['id'] as String;
    _validateId(id);
    // Record the cleanup work before clearing the committed journal so a crash
    // cannot lose track of old resources left by a cloud-sync provider.
    await writeBackupJson(cleanupPending, {'id': id});
    if (await pending.exists()) await pending.delete();
    if (await journal.exists()) await journal.delete();
    if (await _package.exists()) await _package.delete();
    if (await _originalPreferences.exists()) {
      await _originalPreferences.delete();
    }
    return _retryCleanup();
  }

  Future<bool> _retryCleanup() async {
    if (!await cleanupPending.exists()) return false;
    final request = _read(await cleanupPending.readAsString());
    final id = request['id'] as String;
    _validateId(id);
    var deferred = false;
    for (final resource in locations.resources) {
      for (final kind in ['old', 'new']) {
        try {
          await cleanupDelete(_sibling(resource, id, kind));
        } on FileSystemException {
          // The committed data is usable. A cloud placeholder or open handle
          // can temporarily deny removal of its previous sibling.
          deferred = true;
        }
      }
    }
    if (!deferred) await cleanupPending.delete();
    return deferred;
  }

  Future<void> _report(bool success, String message) =>
      writeBackupJson(lastResult, {
        'success': success,
        'message': message,
        'at': DateTime.now().toIso8601String()
      });
  Map<String, dynamic> _read(String source) =>
      Map<String, dynamic>.from(jsonDecode(source) as Map);
  void _validateId(String id) {
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
      throw StateError('Invalid restore request.');
    }
  }

  String _sibling(BackupResource resource, String id, String kind) => p.join(
      p.dirname(resource.path),
      '.${p.basename(resource.path)}.lotus-$kind-$id');
}
