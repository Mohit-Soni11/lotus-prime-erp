import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/backup_restore/application/backup_coordinator.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_http_transport.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_restore_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_store.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_backup_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/backup_record.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/backup_schedule.dart';
import 'backup_restore_test_support.dart';
import 'google_drive_backup_test_support.dart';

void main() {
  late BackupFixture fixture;
  late BackupCoordinator controller;
  late ReceivePort ownerPort;
  late bool uploadSucceeds;
  setUp(() async {
    uploadSucceeds = false;
    ownerPort = ReceivePort();
    fixture = BackupFixture(
        await Directory.systemTemp.createTemp('lotus-coordinator-'));
    await fixture.seed();
    final http = FakeBackupHttp((uri, method, headers, body) async {
      if (!uploadSucceeds) {
        return const BackupHttpResponse(503, {}, Stream.empty());
      }
      if (uri.path == '/drive/v3/files') {
        return backupJsonResponse({'files': []});
      }
      if (uri.path == '/upload/drive/v3/files') {
        return backupJsonResponse({}, headers: {
          'location': 'https://www.googleapis.com/upload/session/test'
        });
      }
      if (uri.path == '/upload/session/test') {
        return backupJsonResponse({
          'id': 'verified-drive-backup',
          'md5Checksum': md5.convert(body).toString(),
          'size': '${body.length}'
        });
      }
      throw StateError('Unexpected Google Drive request: ${uri.path}');
    });
    controller = BackupCoordinator(
        locations: fixture.locations,
        store: BackupStore(fixture.locations),
        preferences: fixture.preferences,
        drive: GoogleDriveBackupService(
            auth: await connectedTestGoogle(http), http: http),
        restore: BackupRestoreService(fixture.locations, fixture.preferences,
            clearSession: () async {}),
        requireOwner: () async => ownerPort.sendPort.send(null));
    await controller.initialize();
  });
  tearDown(() async {
    controller.dispose();
    ownerPort.close();
    await fixture.directory.delete(recursive: true);
  });

  test('background archive work completes and concurrent jobs cannot overlap',
      () async {
    final first = controller.backupNow();
    await expectLater(controller.backupNow(), throwsStateError);
    await first;
    expect(controller.records, hasLength(1));
    expect(await File(controller.records.single.localPath!).exists(), isTrue);
    expect(fixture.amount(), 125);
    expect(controller.busy, isFalse);
  });

  test('Drive outage keeps a verified local backup and records a retry',
      () async {
    await controller.saveSettings(BackupSettings(
        localFolder: fixture.locations.local.path, googleDriveEnabled: true));
    await controller.backupNow();
    expect(controller.records.single.cloudError, isNotNull);
    expect(await File(controller.records.single.localPath!).exists(), isTrue);
    expect(controller.records.single.driveId, isNull);
    expect(controller.settings!.schedule.lastCompletedAt, isNotNull);
    expect(fixture.amount(), 125);
    await controller.scheduledTick(DateTime.now());
    expect(controller.records, hasLength(1));
  });

  test('Drive-only backup removes local staging after verified upload',
      () async {
    uploadSucceeds = true;
    await controller.saveSettings(BackupSettings(
        localFolder: fixture.locations.local.path,
        localEnabled: false,
        googleDriveEnabled: true));
    await controller.backupNow();
    final record = controller.records.single;
    expect(record.localPath, isNull);
    expect(record.driveId, 'verified-drive-backup');
    expect(controller.cloudRecords.single.id, record.id);
    expect(
        await fixture.locations.local
            .list()
            .where((item) => item.path.endsWith('.lotusbackup'))
            .isEmpty,
        isTrue);
    expect((await controller.store.records()).single.localPath, isNull);
  });

  test('failed Drive-only upload keeps a copy until retry succeeds', () async {
    await controller.saveSettings(BackupSettings(
        localFolder: fixture.locations.local.path,
        localEnabled: false,
        googleDriveEnabled: true));
    await controller.backupNow();
    final pending = controller.records.single;
    expect(pending.localRequested, isFalse);
    expect(await File(pending.localPath!).exists(), isTrue);
    expect(pending.cloudError, isNotNull);

    uploadSucceeds = true;
    await controller.retryUpload(pending);
    expect(controller.records.single.localPath, isNull);
    expect(controller.records.single.driveId, 'verified-drive-backup');
    expect(await File(pending.localPath!).exists(), isFalse);
  });

  test('Both destinations retain local file and verified Drive record',
      () async {
    uploadSucceeds = true;
    await controller.saveSettings(BackupSettings(
        localFolder: fixture.locations.local.path, googleDriveEnabled: true));
    await controller.backupNow();
    final record = controller.records.single;
    expect(await File(record.localPath!).exists(), isTrue);
    expect(record.driveId, 'verified-drive-backup');
  });

  test('both backup destinations may be left unselected', () async {
    await controller.saveSettings(BackupSettings(
        localFolder: fixture.locations.local.path, localEnabled: false));
    expect(controller.settings!.localEnabled, isFalse);
    expect(controller.settings!.googleDriveEnabled, isFalse);
  });

  test('retrying an older upload does not change the latest backup', () async {
    final older = BackupRecord(
        id: 'older',
        name: 'older.lotusbackup',
        createdAt: DateTime.utc(2026, 1, 1),
        size: 1,
        sha256: 'a' * 64);
    final newer = BackupRecord(
        id: 'newer',
        name: 'newer.lotusbackup',
        createdAt: DateTime.utc(2026, 1, 2),
        size: 1,
        sha256: 'b' * 64);
    await controller.store.put(older);
    await controller.store.put(newer);
    await controller.store.put(older.uploadFailed('Retry needed'));
    expect((await controller.store.records()).map((item) => item.id),
        ['newer', 'older']);
  });

  test(
      'a due automatic backup runs once and does not duplicate on the next tick',
      () async {
    final now = DateTime.now();
    await controller.saveSettings(BackupSettings(
        localFolder: fixture.locations.local.path,
        schedule: BackupSchedule(
            frequency: BackupFrequency.daily,
            hour: 0,
            lastCompletedAt: DateTime(now.year, now.month, now.day - 2))));
    await controller.scheduledTick(now);
    await controller.scheduledTick(now.add(const Duration(seconds: 1)));
    expect(controller.records, hasLength(1));
  });

  test('scheduled backup uses the chosen local folder and Google Drive',
      () async {
    uploadSucceeds = true;
    final now = DateTime.now();
    final chosenFolder = Directory('${fixture.directory.path}\\ChosenBackups');
    await controller.saveSettings(BackupSettings(
        localFolder: chosenFolder.path,
        localEnabled: true,
        googleDriveEnabled: true,
        schedule: BackupSchedule(
            frequency: BackupFrequency.daily,
            hour: 0,
            lastCompletedAt: DateTime(now.year, now.month, now.day - 2))));

    await controller.scheduledTick(now);

    final backup = controller.records.single;
    expect(backup.localPath, startsWith(chosenFolder.path));
    expect(await File(backup.localPath!).exists(), isTrue);
    expect(backup.driveId, 'verified-drive-backup');
  });

  test(
      'scheduled business errors stay in the workspace and a later tick retries',
      () async {
    final now = DateTime.now();
    await controller.saveSettings(BackupSettings(
        localFolder: fixture.locations.local.path,
        schedule: BackupSchedule(
            frequency: BackupFrequency.daily,
            hour: 0,
            lastCompletedAt: DateTime(now.year, now.month, now.day - 2))));
    final database = File(fixture.locations.resources.first.path);
    final saved = await database.readAsBytes();
    await database.delete();
    await controller.scheduledTick(now);
    expect(controller.error, isNotNull);
    expect(controller.records, isEmpty);
    await database.writeAsBytes(saved);
    await controller.scheduledTick(now);
    expect(controller.records, hasLength(1));
    expect(controller.error, isNull);
  });

  test('restore staging runs off the UI and prevents further backup writes',
      () async {
    await controller.backupNow();
    await controller.prepareRestore(File(controller.records.single.localPath!));
    expect(controller.restorePending, isTrue);
    expect(fixture.amount(), 125);
    expect(await controller.restore.pending.exists(), isTrue);
    await expectLater(controller.backupNow(), throwsStateError);
  });
}
