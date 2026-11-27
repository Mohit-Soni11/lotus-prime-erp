import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_archive_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_file_safety.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_locations.dart';
import 'backup_restore_test_support.dart';

void main() {
  late BackupFixture fixture;
  setUp(() async {
    fixture = BackupFixture(
        await Directory.systemTemp.createTemp('lotus-backup-test-'));
    await fixture.seed();
  });
  tearDown(() async => fixture.directory.delete(recursive: true));

  test(
      'complete backup round trip includes both databases, photos and settings',
      () async {
    final service = BackupArchiveService(fixture.locations);
    final record = await service.create(
        fixture.locations.local.path, await fixture.preferences.read());
    expect(record.sha256, await backupFileHash(File(record.localPath!)));
    final result = await service.verify(File(record.localPath!));
    final db = sqlite3.open(result.resourcePath(fixture.locations.resources[0]),
        mode: OpenMode.readOnly);
    try {
      expect(db.select('SELECT amount FROM bills').single['amount'], 125);
    } finally {
      db.dispose();
    }
    expect(
        await File('${result.directory.path}/payload/media/item.jpg')
            .readAsBytes(),
        [1, 2, 3, 4]);
    expect(
        await File('${result.directory.path}/preferences.json').readAsString(),
        contains('INR'));
    expect(fixture.amount(), 125);
    await deleteBackupEntity(result.directory.path);
  });

  test('live WAL rows are captured without changing the source', () async {
    final writer = sqlite3.open(fixture.locations.resources[0].path);
    writer.execute('PRAGMA journal_mode=WAL');
    writer.execute('UPDATE bills SET amount=950');
    try {
      final service = BackupArchiveService(fixture.locations);
      final record = await service.create(fixture.locations.local.path, {});
      final checked = await service.verify(File(record.localPath!));
      final db =
          sqlite3.open(checked.resourcePath(fixture.locations.resources[0]));
      try {
        expect(db.select('SELECT amount FROM bills').single['amount'], 950);
      } finally {
        db.dispose();
      }
      expect(fixture.amount(), 950);
      await deleteBackupEntity(checked.directory.path);
    } finally {
      writer.dispose();
    }
  });

  test('a future database schema is rejected before it can be restored',
      () async {
    final business = fixture.locations.resources.first;
    final db = sqlite3.open(business.path);
    try {
      db.execute('PRAGMA user_version=4');
    } finally {
      db.dispose();
    }
    final newer = BackupLocations(root: fixture.locations.root, resources: [
      BackupResource(business.id, business.path, schemaVersion: 4),
      ...fixture.locations.resources.skip(1),
    ]);
    final record =
        await BackupArchiveService(newer).create(newer.local.path, {});
    await expectLater(
        BackupArchiveService(fixture.locations).verify(File(record.localPath!)),
        throwsStateError);
    expect(fixture.amount(), 125);
  });

  test('unsafe backup destinations and archive paths are rejected', () async {
    final service = BackupArchiveService(fixture.locations);
    await expectLater(service.create(fixture.locations.resources[2].path, {}),
        throwsStateError);
    for (final path in [
      '../escape',
      '/escape',
      'payload\\escape',
      'C:/escape',
      'payload/CON',
      'payload/x.'
    ]) {
      expect(() => validateArchivePath(path), throwsFormatException);
    }
  });

  Future<File> altered(void Function(Archive archive) change) async {
    final service = BackupArchiveService(fixture.locations);
    final record = await service.create(fixture.locations.local.path, {});
    final archive =
        ZipDecoder().decodeBytes(await File(record.localPath!).readAsBytes());
    change(archive);
    return File('${fixture.directory.path}/altered.lotusbackup')
        .writeAsBytes(ZipEncoder().encode(archive));
  }

  test('modified payload is rejected even when the ZIP itself remains readable',
      () async {
    final file = await altered((archive) {
      archive.removeFile(archive.findFile('preferences.json')!);
      archive.add(ArchiveFile('preferences.json', 2, [91, 93]));
    });
    await expectLater(BackupArchiveService(fixture.locations).verify(file),
        throwsFormatException);
    expect(fixture.amount(), 125);
  });

  test('backups made before PDF reconciliation remain restorable', () async {
    final file = await altered((archive) {
      final entry = archive.findFile('manifest.json')!;
      final manifest = jsonDecode(utf8.decode(entry.content as List<int>))
          as Map<String, dynamic>;
      manifest.remove('missingIssuedDocuments');
      final bytes = utf8.encode(jsonEncode(manifest));
      archive.removeFile(entry);
      archive.add(ArchiveFile('manifest.json', bytes.length, bytes));
    });
    final verified = await BackupArchiveService(fixture.locations).verify(file);
    try {
      expect(verified.manifest.containsKey('missingIssuedDocuments'), isFalse);
    } finally {
      await deleteBackupEntity(verified.directory.path);
    }
  });

  test('path traversal cannot write outside the verification workspace',
      () async {
    final file = await altered(
        (archive) => archive.add(ArchiveFile('../escaped.txt', 1, [1])));
    await expectLater(BackupArchiveService(fixture.locations).verify(file),
        throwsFormatException);
    expect(
        await File('${fixture.directory.path}/escaped.txt').exists(), isFalse);
  });

  test('missing linked media is reported without losing financial backup data',
      () async {
    await File('${fixture.locations.resources[2].path}/item.jpg').delete();
    final service = BackupArchiveService(fixture.locations);
    final record = await service.create(
        fixture.locations.local.path, await fixture.preferences.read());
    expect(record.missingMediaCount, 1);
    final checked = await service.verify(File(record.localPath!));
    expect(checked.manifest['missingMedia'], hasLength(1));
    expect(fixture.amount(), 125);
  });

  test('linked archive entries are rejected before content is decompressed',
      () async {
    final file = await altered((archive) {
      final linked = ArchiveFile('payload/media/link', 4, [116, 101, 115, 116])
        ..mode = 0xa1ff;
      archive.add(linked);
    });
    await expectLater(BackupArchiveService(fixture.locations).verify(file),
        throwsFormatException);
  });
}
