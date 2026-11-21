import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:lotus_erp/features/settings/backup_restore/application/backup_application_lease.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_store.dart';
import 'backup_restore_test_support.dart';

void main() {
  test('damaged metadata is preserved while local recovery remains available',
      () async {
    final fixture = BackupFixture(
        await Directory.systemTemp.createTemp('lotus-backup-metadata-'));
    addTearDown(() => fixture.directory.delete(recursive: true));
    await fixture.locations.root.create(recursive: true);
    final damaged = File(p.join(fixture.locations.root.path, 'catalog.json'));
    await damaged.writeAsString('{broken');
    final store = BackupStore(fixture.locations);
    expect(await store.records(), isEmpty);
    expect(store.warning, isNotNull);
    final saved = await fixture.locations.root
        .list()
        .where((file) => file.path.contains('unreadable-'))
        .toList();
    expect(saved, hasLength(1));
    expect(await File(saved.single.path).readAsString(), '{broken');
  });

  test('Windows application lease prevents a second live instance', () async {
    final fixture = BackupFixture(
        await Directory.systemTemp.createTemp('lotus-backup-lease-'));
    final first = BackupApplicationLease();
    final second = BackupApplicationLease();
    addTearDown(() async {
      await first.release();
      await second.release();
      await fixture.directory.delete(recursive: true);
    });
    await first.acquire(fixture.locations);
    await expectLater(second.acquire(fixture.locations),
        throwsA(isA<BackupStartupException>()));
    await first.release();
    await second.acquire(fixture.locations);
  }, skip: !Platform.isWindows);
}
