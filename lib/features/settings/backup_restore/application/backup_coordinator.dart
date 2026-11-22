import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../data/backup_archive_service.dart';
import '../data/backup_file_safety.dart';
import '../data/backup_locations.dart';
import '../data/backup_restore_service.dart';
import '../data/backup_store.dart';
import '../data/google_drive_backup_service.dart';
import '../domain/backup_record.dart';
import 'backup_isolate_jobs.dart';

class BackupCoordinator extends ChangeNotifier {
  BackupCoordinator(
      {required this.locations,
      required this.store,
      required this.preferences,
      required this.drive,
      required this.restore,
      required this.requireOwner});
  final BackupLocations locations;
  final BackupStore store;
  final BusinessPreferences preferences;
  final GoogleDriveBackupService drive;
  final BackupRestoreService restore;
  final Future<void> Function() requireOwner;
  BackupSettings? settings;
  List<BackupRecord> records = [];
  List<BackupRecord> cloudRecords = [];
  bool busy = false;
  bool initialized = false;
  bool restorePending = false;
  bool signingIn = false;
  String phase = '';
  String? error;
  double? progress;
  bool _disposed = false;
  DateTime? _cloudRetryAfter;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (initialized) return;
    await _operation('Loading backup settings', () async {
      settings = await store.settings();
      records = await store.records();
      error = store.warning;
      try {
        await drive.auth.load();
      } catch (_) {
        error =
            'Google Drive connection could not be loaded. Local backup is still available; reconnect Google Drive when ready.';
      }
      restorePending = await restore.pending.exists();
      initialized = true;
    });
  }

  Future<void> saveSettings(BackupSettings value) async {
    await _operation('Saving backup settings', () async {
      await requireOwner();
      locations.validateDestination(value.localFolder);
      await requireNoLinks(value.localFolder);
      if (value.googleDriveEnabled && !drive.auth.connected) {
        throw StateError('Connect your Google account first.');
      }
      await store.saveSettings(value);
      settings = value;
    });
  }

  Future<void> connectGoogle() =>
      _operation('Waiting for Google sign-in', () async {
        await requireOwner();
        signingIn = true;
        _emit();
        try {
          await drive.auth.signIn();
          cloudRecords = await drive.list();
        } finally {
          signingIn = false;
        }
      });

  Future<void> disconnectGoogle() =>
      _operation('Disconnecting Google Drive', () async {
        await requireOwner();
        await drive.auth.disconnect();
        cloudRecords = [];
        settings = settings!.copyWith(googleDriveEnabled: false);
        await store.saveSettings(settings!);
      });

  Future<void> refreshCloud() =>
      _operation('Loading Google Drive backups', () async {
        await requireOwner();
        cloudRecords = await drive.list();
      });

  Future<void> backupNow() =>
      _operation('Creating a verified local backup', () async {
        await requireOwner();
        final destination = settings!;
        if (!destination.localEnabled && !destination.googleDriveEnabled) {
          throw StateError('Select a backup destination first.');
        }
        if (destination.googleDriveEnabled && !drive.auth.connected) {
          throw StateError('Connect your Google account first.');
        }
        final folder = destination.localFolder;
        final values = await preferences.read();
        var record = await Isolate.run(
            CreateLocalBackupJob(locations, folder, values).call);
        record = record.withLocalPreference(destination.localEnabled);
        await store.put(record);
        settings = destination.copyWith(
            schedule: destination.schedule.completed(DateTime.now()));
        await store.saveSettings(settings!);
        records = await store.records();
        _emit();
        if (destination.googleDriveEnabled) {
          try {
            record = await _upload(record);
          } catch (_) {
            record = record.uploadFailed(
                'Google Drive upload needs a retry. A local recovery copy is safe.');
            error = record.cloudError;
            _cloudRetryAfter = DateTime.now().add(const Duration(minutes: 5));
          }
          await store.put(record);
          record = await _finalizeDriveBackup(record);
          await store.put(record);
          records = await store.records();
          if (record.driveId != null) {
            cloudRecords = [
              record.withoutLocalCopy(),
              ...cloudRecords.where((item) => item.id != record.id)
            ];
          }
        }
      });

  Future<BackupRecord> _upload(BackupRecord record) async {
    phase = 'Uploading backup to Google Drive';
    progress = 0;
    _emit();
    final id = await drive.upload(record, onProgress: _updateProgress);
    return record.uploaded(id);
  }

  Future<BackupRecord> _finalizeDriveBackup(BackupRecord record) async {
    if (record.localRequested || record.driveId == null) return record;
    final path = record.localPath;
    if (path == null ||
        p.basename(path) != record.name ||
        !record.name.endsWith('.lotusbackup')) {
      throw StateError('The temporary backup path is invalid.');
    }
    try {
      await deleteBackupEntity(path);
      return record.withoutLocalCopy();
    } catch (_) {
      error =
          'Google Drive backup is verified, but the temporary local copy could not be removed.';
      return record;
    }
  }

  Future<void> retryUpload(BackupRecord record) =>
      _operation('Uploading saved backup', () async {
        await requireOwner();
        var uploaded = await _upload(record);
        await store.put(uploaded);
        uploaded = await _finalizeDriveBackup(uploaded);
        await store.put(uploaded);
        records = await store.records();
        cloudRecords = [
          uploaded.withoutLocalCopy(),
          ...cloudRecords.where((item) => item.id != uploaded.id)
        ];
        _cloudRetryAfter = null;
      });

  Future<File> download(BackupRecord record) async {
    File? downloaded;
    await _operation('Downloading Google Drive backup', () async {
      await requireOwner();
      downloaded = await drive.download(
          record,
          Directory(
              '${locations.root.path}${Platform.pathSeparator}CloudCache'),
          onProgress: _updateProgress);
    });
    return downloaded!;
  }

  Future<VerifiedBackup> inspect(File file) async {
    VerifiedBackup? verified;
    await _operation('Checking backup integrity', () async {
      await requireOwner();
      verified =
          await Isolate.run(VerifyLocalBackupJob(locations, file.path).call);
    });
    return verified!;
  }

  Future<void> prepareRestore(File file) =>
      _operation('Preparing safe restore', () async {
        await requireOwner();
        // Staging is filesystem-only; platform preferences are applied at boot.
        await Isolate.run(PrepareLocalRestoreJob(locations, file.path).call);
        restorePending = true;
      });

  Future<void> scheduledTick(DateTime now) async {
    if (!initialized || busy || restorePending || settings == null) return;
    if (!settings!.localEnabled && !settings!.googleDriveEnabled) return;
    if (settings!.schedule.isDue(now)) {
      try {
        await backupNow();
      } catch (_) {/* The next tick retries a missed backup. */}
      return;
    }
    if (settings!.googleDriveEnabled &&
        drive.auth.connected &&
        (_cloudRetryAfter == null || !now.isBefore(_cloudRetryAfter!))) {
      final pending = records.where(
          (record) => record.cloudError != null && record.driveId == null);
      if (pending.isNotEmpty) {
        _cloudRetryAfter = now.add(const Duration(minutes: 5));
        try {
          await retryUpload(pending.last);
        } catch (_) {/* Keep the local backup and retry later. */}
      }
    }
  }

  void _updateProgress(double value) {
    progress = value;
    _emit();
  }

  Future<void> _operation(String label, Future<void> Function() action) async {
    if (busy) {
      throw StateError(
          'Another backup operation is running. Wait for it to finish.');
    }
    if (restorePending) {
      throw StateError('Restart Lotus ERP to complete the prepared restore.');
    }
    busy = true;
    phase = label;
    error = null;
    progress = null;
    _emit();
    try {
      await action();
    } catch (exception) {
      error = exception
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('FormatException: ', '');
      rethrow;
    } finally {
      busy = false;
      signingIn = false;
      progress = null;
      phase = '';
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
