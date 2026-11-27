import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_archive_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_file_safety.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_locations.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_restore_service.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:sqlite3/sqlite3.dart';

import 'backup_restore_test_support.dart';

void main() {
  late BackupFixture fixture;
  late Directory currentSupport;
  late Directory legacySupport;
  late BackupLocations locations;

  setUp(() async {
    fixture = BackupFixture(
        await Directory.systemTemp.createTemp('issued-backup-test-'));
    await fixture.seed();
    currentSupport = Directory(p.join(fixture.directory.path, 'Current'));
    legacySupport = Directory(p.join(fixture.directory.path, 'Legacy'));
    locations = BackupLocations(
      root: fixture.locations.root,
      legacyIssuedInvoicesPath:
          p.join(legacySupport.path, 'lotus_erp', 'issued_invoices'),
      resources: [
        ...fixture.locations.resources,
        BackupResource('issued_invoices',
            p.join(currentSupport.path, 'lotus_erp', 'issued_invoices')),
      ],
    );
    final db = sqlite3.open(fixture.locations.resources.first.path);
    try {
      db.execute('ALTER TABLE bills ADD COLUMN bill_no TEXT');
      db.execute("UPDATE bills SET bill_no = 'INV-1'");
      db.execute(
          'CREATE TABLE sales_orders(id INTEGER PRIMARY KEY, order_no TEXT)');
      db.execute(
          'CREATE TABLE order_advances(order_id INTEGER, amount_paid REAL)');
      db.execute("INSERT INTO sales_orders VALUES (2, 'BOOK-2')");
      db.execute('INSERT INTO order_advances VALUES (2, 100)');
      db.execute('CREATE TABLE return_vouchers('
          'id INTEGER PRIMARY KEY, voucher_no TEXT, status TEXT)');
      db.execute(
          "INSERT INTO return_vouchers VALUES (3, 'RETURN-3', 'POSTED')");
    } finally {
      db.dispose();
    }
  });

  tearDown(() async => fixture.directory.delete(recursive: true));

  test('the legacy invoice folder cannot be selected as backup destination',
      () {
    expect(
        () => locations.validateDestination(
            p.join(locations.legacyIssuedInvoicesPath!, 'Backups')),
        throwsStateError);
  });

  test('legacy originals and revisions are copied into the verified package',
      () async {
    final legacy =
        IssuedInvoiceArchive(directoryProvider: () async => legacySupport);
    final current =
        IssuedInvoiceArchive(directoryProvider: () async => currentSupport);
    final original = await _pdf('Original sales invoice');
    final revision = await _pdf('Issued sales revision');
    await legacy.saveIfAbsent(IssuedInvoiceKind.sales, 1, 'INV-1', original);
    await legacy.saveRevision(IssuedInvoiceKind.sales, 1, 'INV-1', revision);
    await current.saveIfAbsent(
        IssuedInvoiceKind.booking, 2, 'BOOK-2', await _pdf('Booking'));
    await current.saveIfAbsent(IssuedInvoiceKind.returnVoucher, 3, 'RETURN-3',
        await _pdf('Return voucher'));

    final service = BackupArchiveService(locations);
    final record = await service.create(locations.local.path, {});
    expect(record.missingMediaCount, 0);
    final verified = await service.verify(File(record.localPath!));
    try {
      expect(verified.manifest['missingIssuedDocuments'], isEmpty);
      final originalPath = p.join(
          verified.directory.path,
          'payload',
          'issued_invoices',
          IssuedInvoiceArchive.relativePdfPath(
              IssuedInvoiceKind.sales, 1, 'INV-1'));
      expect(await File(originalPath).readAsBytes(), original);
      final revisionDir = Directory(p.join(p.dirname(originalPath), 'revisions',
          p.basenameWithoutExtension(originalPath)));
      final revisions =
          await revisionDir.list().where((e) => e is File).toList();
      expect(revisions, hasLength(1));
      expect(await File(revisions.single.path).readAsBytes(), revision);
    } finally {
      await deleteBackupEntity(verified.directory.path);
    }
  });

  test('a legacy issued PDF opens from the current archive after restore',
      () async {
    final legacy =
        IssuedInvoiceArchive(directoryProvider: () async => legacySupport);
    final original = await _pdf('Legacy original');
    final revision = await _pdf('Legacy revision');
    await legacy.saveIfAbsent(IssuedInvoiceKind.sales, 1, 'INV-1', original);
    await legacy.saveRevision(IssuedInvoiceKind.sales, 1, 'INV-1', revision);
    final record =
        await BackupArchiveService(locations).create(locations.local.path, {});

    final destination = BackupFixture(
        await Directory.systemTemp.createTemp('issued-restore-test-'));
    addTearDown(() => destination.directory.delete(recursive: true));
    await destination.seed();
    final destinationSupport =
        Directory(p.join(destination.directory.path, 'Support'));
    final destinationLocations = BackupLocations(
      root: destination.locations.root,
      resources: [
        ...destination.locations.resources,
        BackupResource('issued_invoices',
            p.join(destinationSupport.path, 'lotus_erp', 'issued_invoices')),
      ],
    );
    final restore = BackupRestoreService(
        destinationLocations, destination.preferences,
        clearSession: () async {});
    await restore.prepare(File(record.localPath!));
    expect(await restore.applyPending(), isTrue);
    final restored =
        IssuedInvoiceArchive(directoryProvider: () async => destinationSupport);
    expect(await restored.read(IssuedInvoiceKind.sales, 1, 'INV-1'), revision);
    expect(
        await File(p.join(
                destinationLocations.resources.last.path,
                IssuedInvoiceArchive.relativePdfPath(
                    IssuedInvoiceKind.sales, 1, 'INV-1')))
            .readAsBytes(),
        original);
  });

  test('missing original invoice PDFs are listed without losing the backup',
      () async {
    final service = BackupArchiveService(locations);
    final record = await service.create(locations.local.path, {});
    expect(record.missingMediaCount, 3);
    final verified = await service.verify(File(record.localPath!));
    try {
      expect(verified.manifest['missingIssuedDocuments'], [
        'sales: INV-1 (record 1)',
        'booking: BOOK-2 (record 2)',
        'returnVoucher: RETURN-3 (record 3)',
      ]);
      expect(fixture.amount(), 125);
    } finally {
      await deleteBackupEntity(verified.directory.path);
    }
  });

  test('a valid legacy PDF replaces a damaged current copy in the package',
      () async {
    final legacy =
        IssuedInvoiceArchive(directoryProvider: () async => legacySupport);
    final goodPdf = await _pdf('Legacy issued document');
    await legacy.saveIfAbsent(IssuedInvoiceKind.sales, 1, 'INV-1', goodPdf);
    final currentFile = File(p.join(
        locations.resources.last.path,
        IssuedInvoiceArchive.relativePdfPath(
            IssuedInvoiceKind.sales, 1, 'INV-1')));
    await currentFile.parent.create(recursive: true);
    await currentFile.writeAsBytes([1, 2, 3]);

    final record =
        await BackupArchiveService(locations).create(locations.local.path, {});
    final verified =
        await BackupArchiveService(locations).verify(File(record.localPath!));
    try {
      final packaged = File(p.join(
          verified.directory.path,
          'payload',
          'issued_invoices',
          IssuedInvoiceArchive.relativePdfPath(
              IssuedInvoiceKind.sales, 1, 'INV-1')));
      expect(await packaged.readAsBytes(), goodPdf);
      expect(verified.manifest['missingIssuedDocuments'],
          isNot(contains('sales: INV-1 (record 1)')));
      expect(await currentFile.readAsBytes(), [1, 2, 3]);
    } finally {
      await deleteBackupEntity(verified.directory.path);
    }
  });

  test('corrupt latest revision is reported as unavailable', () async {
    final current =
        IssuedInvoiceArchive(directoryProvider: () async => currentSupport);
    await current.saveIfAbsent(
        IssuedInvoiceKind.sales, 1, 'INV-1', await _pdf('Original'));
    await current.saveRevision(
        IssuedInvoiceKind.sales, 1, 'INV-1', await _pdf('Revision'));
    final base = p.join(
        locations.resources.last.path,
        IssuedInvoiceArchive.relativePdfPath(
            IssuedInvoiceKind.sales, 1, 'INV-1'));
    final revisions = Directory(
        p.join(p.dirname(base), 'revisions', p.basenameWithoutExtension(base)));
    final file =
        await revisions.list().where((e) => e is File).cast<File>().first;
    await file.writeAsBytes([1, 2, 3]);

    final record =
        await BackupArchiveService(locations).create(locations.local.path, {});
    final verified =
        await BackupArchiveService(locations).verify(File(record.localPath!));
    try {
      expect(verified.manifest['missingIssuedDocuments'],
          contains('sales: INV-1 (record 1)'));
    } finally {
      await deleteBackupEntity(verified.directory.path);
    }
  });
}

Future<Uint8List> _pdf(String label) async {
  final document = pw.Document()
    ..addPage(pw.Page(build: (_) => pw.Text(label)));
  return document.save();
}
