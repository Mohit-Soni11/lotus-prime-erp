import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_archive_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_locations.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_file_safety.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_restore_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_store.dart';
import 'backup_restore_test_support.dart';

void main() {
  late BackupFixture original, destination;
  setUp(() async {
    original =
        BackupFixture(await Directory.systemTemp.createTemp('lotus-source-'));
    destination =
        BackupFixture(await Directory.systemTemp.createTemp('lotus-target-'));
    await original.seed(amount: 125);
    await destination.seed(amount: 999);
    destination.preferences.values['currency'] = 'OLD';
  });
  tearDown(() async {
    await original.directory.delete(recursive: true);
    await destination.directory.delete(recursive: true);
  });
  Future<File> package() async {
    final record = await BackupArchiveService(original.locations).create(
        original.locations.local.path, await original.preferences.read());
    return File(record.localPath!);
  }

  BackupRestoreService service({Future<void> Function()? clearSession}) =>
      BackupRestoreService(destination.locations, destination.preferences,
          clearSession: clearSession ?? () async {});

  test('restore is staged without changing live records and commits on restart',
      () async {
    var signedOut = false;
    final restore = service(clearSession: () async {
      signedOut = true;
    });
    await restore.prepare(await package());
    expect(destination.amount(), 999);
    expect(signedOut, isFalse);
    expect(await restore.applyPending(), isTrue);
    expect(destination.amount(), 125);
    expect(signedOut, isTrue);
    expect(destination.preferences.values['currency'], 'INR');
    expect(destination.preferences.values['profile'],
        p.join(destination.locations.resources[2].path, 'item.jpg'));
    final db = sqlite3.open(destination.locations.resources[0].path);
    try {
      expect(db.select('SELECT photo_path FROM bills').single['photo_path'],
          p.join(destination.locations.resources[2].path, 'item.jpg'));
    } finally {
      db.dispose();
    }
    expect(await restore.pending.exists(), isFalse);
    expect(await restore.journal.exists(), isFalse);
    final recovery = await destination.locations.recovery
        .list()
        .where((item) => item.path.endsWith('.lotusbackup'))
        .toList();
    expect(recovery, hasLength(1));
    final checked = await BackupArchiveService(destination.locations)
        .verify(File(recovery.single.path));
    final prior =
        sqlite3.open(checked.resourcePath(destination.locations.resources[0]));
    try {
      expect(prior.select('SELECT amount FROM bills').single['amount'], 999);
    } finally {
      prior.dispose();
    }
    expect(await restore.applyPending(), isFalse);
  });

  test('issued invoice PDF is restored byte for byte with both databases',
      () async {
    final sourcePdf = BackupResource(
      'issued_invoices',
      p.join(original.directory.path, 'Support', 'issued_invoices'),
    );
    final destinationPdf = BackupResource(
      'issued_invoices',
      p.join(destination.directory.path, 'Support', 'issued_invoices'),
    );
    final sourceLocations = BackupLocations(
      root: original.locations.root,
      resources: [...original.locations.resources, sourcePdf],
    );
    final destinationLocations = BackupLocations(
      root: destination.locations.root,
      resources: [...destination.locations.resources, destinationPdf],
    );
    final pdfBytes = '%PDF-original-issued-invoice'.codeUnits;
    final issued = File(p.join(sourcePdf.path, 'sales', '9_ABC.pdf'));
    await issued.parent.create(recursive: true);
    await issued.writeAsBytes(pdfBytes);
    final backup = await BackupArchiveService(sourceLocations).create(
      sourceLocations.local.path,
      await original.preferences.read(),
    );
    final restored = BackupRestoreService(
      destinationLocations,
      destination.preferences,
      clearSession: () async {},
    );

    await restored.prepare(File(backup.localPath!));
    expect(await restored.applyPending(), isTrue);
    expect(destination.amount(), 125);
    expect(
      await File(p.join(destinationPdf.path, 'sales', '9_ABC.pdf'))
          .readAsBytes(),
      pdfBytes,
    );
  });

  test('a cloud-sync cleanup denial does not block a committed restore',
      () async {
    var denyOldDirectory = true;
    final restore = BackupRestoreService(
        destination.locations, destination.preferences,
        clearSession: () async {}, cleanupDelete: (path) async {
      if (denyOldDirectory && path.contains('.Photos.lotus-old-')) {
        throw FileSystemException(
            'Access is denied', path, const OSError('Access is denied', 5));
      }
      await deleteBackupEntity(path);
    });
    await restore.prepare(await package());
    expect(await restore.applyPending(), isTrue);
    expect(destination.amount(), 125);
    expect(await restore.pending.exists(), isFalse);
    expect(await restore.journal.exists(), isFalse);
    expect(await restore.cleanupPending.exists(), isTrue);
    expect(jsonDecode(await restore.lastResult.readAsString())['message'],
        contains('cleanup will retry'));

    expect(await restore.applyPending(), isFalse);
    expect(await restore.cleanupPending.exists(), isTrue);

    denyOldDirectory = false;
    expect(await restore.applyPending(), isFalse);
    expect(await restore.cleanupPending.exists(), isFalse);
    expect(destination.amount(), 125);
  });

  test('legacy external photos are included and relocated into managed storage',
      () async {
    final legacy = File(p.join(original.directory.path, 'Legacy', 'photo.jpg'));
    await legacy.parent.create(recursive: true);
    await legacy.writeAsBytes([8, 7, 6, 5]);
    final db = sqlite3.open(original.locations.resources.first.path);
    try {
      db.execute('UPDATE bills SET photo_path=?', [legacy.path]);
    } finally {
      db.dispose();
    }
    original.preferences.values['profile'] = legacy.path;
    final file = await package();
    await legacy.delete();
    final restore = service();
    await restore.prepare(file);
    expect(await restore.applyPending(), isTrue);
    final restored = sqlite3.open(destination.locations.resources.first.path);
    late String photo;
    try {
      photo = restored
          .select('SELECT photo_path FROM bills')
          .single['photo_path'] as String;
    } finally {
      restored.dispose();
    }
    expect(
        p.isWithin(
            destination.locations.resources
                .firstWhere((r) => r.id == 'external_media')
                .path,
            photo),
        isTrue);
    expect(await File(photo).readAsBytes(), [8, 7, 6, 5]);
    expect(destination.preferences.values['profile'], photo);
  });

  test('nested photo paths in JSON columns are relocated after restore',
      () async {
    final sourcePhoto =
        p.join(original.locations.resources[2].path, 'item.jpg');
    final business = sqlite3.open(original.locations.resources.first.path);
    try {
      business.execute('ALTER TABLE bills ADD COLUMN photo_json TEXT');
      business.execute('ALTER TABLE bills ADD COLUMN audit_json TEXT');
      business.execute('UPDATE bills SET photo_json=?, audit_json=?', [
        jsonEncode({
          'items': [
            {'photo': sourcePhoto}
          ]
        }),
        '{ "amount": 125 }',
      ]);
    } finally {
      business.dispose();
    }

    final restore = service();
    await restore.prepare(await package());
    expect(await restore.applyPending(), isTrue);
    final restored = sqlite3.open(destination.locations.resources.first.path);
    try {
      final row =
          restored.select('SELECT photo_json, audit_json FROM bills').single;
      final data =
          jsonDecode(row['photo_json'] as String) as Map<String, dynamic>;
      final photo = (data['items'] as List).single['photo'] as String;
      expect(
          photo, p.join(destination.locations.resources[2].path, 'item.jpg'));
      expect(await File(photo).readAsBytes(), [1, 2, 3, 4]);
      expect(row['audit_json'], '{ "amount": 125 }');
    } finally {
      restored.dispose();
    }
  });

  test('a preferences failure rolls back all replaced resources', () async {
    final restore = service();
    await restore.prepare(await package());
    destination.preferences.failOnce = true;
    await expectLater(restore.applyPending(), throwsStateError);
    expect(destination.amount(), 999);
    expect(destination.preferences.values['currency'], 'OLD');
    expect(await restore.journal.exists(), isFalse);
    expect(await restore.pending.exists(), isFalse);
  });

  test('a changed staged archive is rejected before replacing anything',
      () async {
    final restore = service();
    await restore.prepare(await package());
    final staged = File(p.join(destination.locations.root.path,
        'RestorePending', 'package.lotusbackup'));
    await staged.writeAsString('damaged');
    await expectLater(restore.applyPending(), throwsStateError);
    expect(destination.amount(), 999);
    expect(destination.preferences.values['currency'], 'OLD');
  });

  test('an interrupted file swap is recovered from its durable journal',
      () async {
    final restore = service();
    final id = const Uuid().v4();
    final resource = destination.locations.resources.first;
    final old = p.join(p.dirname(resource.path),
        '.${p.basename(resource.path)}.lotus-old-$id');
    await File(resource.path).rename(old);
    await File(resource.path).writeAsString('incomplete replacement');
    await writeBackupJson(restore.journal, {
      'id': id,
      'phase': 'applying',
      'existed': {
        for (final item in destination.locations.resources) item.id: true
      }
    });
    await writeBackupJson(
        File(p.join(destination.locations.root.path, 'RestorePending',
            'original-preferences.json')),
        destination.preferences.values);
    expect(await restore.applyPending(), isFalse);
    expect(destination.amount(), 999);
    expect(await File(old).exists(), isFalse);
    expect(jsonDecode(await restore.lastResult.readAsString())['success'],
        isFalse);
  });
}
