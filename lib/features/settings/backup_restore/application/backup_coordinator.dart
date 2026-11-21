import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../data/backup_archive_service.dart';
import '../data/backup_file_safety.dart';
import '../data/backup_locations.dart';
import '../data/backup_restore_service.dart';
import '../data/backup_store.dart';
import '../data/google_drive_backup_service.dart';
import '../domain/backup_record.dart';

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

  Future<void> configureGoogle(File file) =>
      _operation('Configuring Google Drive', () async {
        await requireOwner();
        if (await file.length() > 65536) {
          throw const FormatException(
              'Select the Google Desktop OAuth JSON file.');
        }
        await drive.auth.configure(await file.readAsString());
        cloudRecords = [];
        if (settings != null) {
          settings = BackupSettings(
              localFolder: settings!.localFolder, schedule: settings!.schedule);
          await store.saveSettings(settings!);
        }
      });

  Future<void> connectGoogle() =>
      _operation('Waiting for Google sign-in', () async {
        await requireOwner();
        signingIn = true;
        _emit();
        try {
          await drive.auth.signIn();
          cloudRecords = await drive.list();
          settings = BackupSettings(
              localFolder: settings!.localFolder,
              schedule: settings!.schedule,
              googleDriveEnabled: true);
          await store.saveSettings(settings!);
        } finally {
          signingIn = false;
        }
      });

  Future<void> disconnectGoogle() =>
      _operation('Disconnecting Google Drive', () async {
        await requireOwner();
        await drive.auth.disconnect();
        cloudRecords = [];
        settings = BackupSettings(
            localFolder: settings!.localFolder, schedule: settings!.schedule);
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
        final paths = locations;
        final folder = settings!.localFolder;
        final values = await preferences.read();
        var record = await Isolate.run(
            () => BackupArchiveService(paths).create(folder, values));
        await store.put(record);
        settings = BackupSettings(
            localFolder: settings!.localFolder,
            googleDriveEnabled: settings!.googleDriveEnabled,
            schedule: settings!.schedule.completed(DateTime.now()));
        await store.saveSettings(settings!);
        records = await store.records();
        _emit();
        if (settings!.googleDriveEnabled) {
          try {
            record = await _upload(record);
          } catch (_) {
            record = record.uploadFailed(
                'Local backup is safe. Google Drive upload needs a retry.');
            error = record.cloudError;
            _cloudRetryAfter = DateTime.now().add(const Duration(minutes: 5));
          }
          await store.put(record);
          records = await store.records();
        }
      });

  Future<BackupRecord> _upload(BackupRecord record) async {
    phase = 'Uploading backup to Google Drive';
    progress = 0;
    _emit();
    final id = await drive.upload(record, onProgress: _updateProgress);
    return record.uploaded(id);
  }

  Future<void> retryUpload(BackupRecord record) =>
      _operation('Uploading saved backup', () async {
        await requireOwner();
        await store.put(await _upload(record));
        records = await store.records();
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
      final paths = locations;
      verified =
          await Isolate.run(() => BackupArchiveService(paths).verify(file));
    });
    return verified!;
  }

  Future<void> prepareRestore(File file) =>
      _operation('Preparing safe restore', () async {
        await requireOwner();
        final paths = locations;
        final source = file.path;
        // Staging is filesystem-only; platform preferences are applied at boot.
        await Isolate.run(() => BackupRestoreService(
                paths, SharedBusinessPreferences(),
                clearSession: () async {})
            .prepare(File(source)));
        restorePending = true;
      });

  Future<void> scheduledTick(DateTime now) async {
    if (!initialized || busy || restorePending || settings == null) return;
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
