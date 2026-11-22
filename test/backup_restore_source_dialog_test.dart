import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/backup_record.dart';
import 'package:lotus_erp/features/settings/backup_restore/presentation/backup_restore_source_dialog.dart';

BackupRecord _record({String? localPath, String? driveId}) => BackupRecord(
      id: 'backup',
      name: 'backup.lotusbackup',
      createdAt: DateTime.utc(2026, 11, 22),
      size: 1024,
      sha256: 'a' * 64,
      localPath: localPath,
      driveId: driveId,
    );

void main() {
  testWidgets('single-copy backup resolves directly to its source',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const Scaffold();
    })));
    expect(
        await selectBackupRestoreSource(
            context, _record(localPath: 'C:/Backups/backup.lotusbackup'),
            googleDriveConnected: false),
        BackupRestoreSource.local);
    expect(
        await selectBackupRestoreSource(
            context, _record(driveId: 'drive-backup'),
            googleDriveConnected: true),
        BackupRestoreSource.googleDrive);
    expect(find.text('Choose Restore Source'), findsNothing);
  });

  testWidgets('two-copy backup lets the user pick one source', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const Scaffold();
    })));
    final selection = selectBackupRestoreSource(
        context,
        _record(
            localPath: 'C:/Backups/backup.lotusbackup',
            driveId: 'drive-backup'),
        googleDriveConnected: true);
    await tester.pumpAndSettle();
    expect(find.text('Choose Restore Source'), findsOneWidget);
    await tester.tap(find.text('Google Drive Backup'));
    await tester.pumpAndSettle();
    expect(await selection, BackupRestoreSource.googleDrive);
  });
}
