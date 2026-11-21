import 'dart:io';
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
  setUp(() async {
    fixture = BackupFixture(
        await Directory.systemTemp.createTemp('lotus-coordinator-'));
    await fixture.seed();
    final http = FakeBackupHttp((a, b, c, d) async =>
        const BackupHttpResponse(503, {}, Stream.empty()));
    controller = BackupCoordinator(
        locations: fixture.locations,
        store: BackupStore(fixture.locations),
        preferences: fixture.preferences,
        drive: GoogleDriveBackupService(
            auth: await connectedTestGoogle(http), http: http),
        restore: BackupRestoreService(fixture.locations, fixture.preferences,
            clearSession: () async {}),
        requireOwner: () async {});
    await controller.initialize();
  });
  tearDown(() async {
    controller.dispose();
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
