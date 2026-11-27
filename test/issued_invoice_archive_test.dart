import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  late Directory root;
  late IssuedInvoiceArchive archive;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('issued_invoice_test_');
    archive = IssuedInvoiceArchive(directoryProvider: () async => root);
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('reads the issued PDF and never replaces the original', () async {
    final original = await _pdf('Originally issued');
    final revised = await _pdf('Changed later');

    await archive.saveIfAbsent(IssuedInvoiceKind.sales, 17, 'INV-17', original);
    await archive.saveIfAbsent(IssuedInvoiceKind.sales, 17, 'INV-17', revised);

    expect(
      await archive.read(IssuedInvoiceKind.sales, 17, 'INV-17'),
      orderedEquals(original),
    );
    expect(await archive.read(IssuedInvoiceKind.booking, 17, 'INV-17'), isNull);
    expect(
        await archive.read(IssuedInvoiceKind.sales, 17, 'INV-OTHER'), isNull);
  });

  test('rejects a non-PDF before it can be linked', () async {
    expect(
      archive.saveIfAbsent(
        IssuedInvoiceKind.sales,
        17,
        'INV-17',
        Uint8List.fromList([1, 2, 3]),
      ),
      throwsFormatException,
    );
    expect(await archive.read(IssuedInvoiceKind.sales, 17, 'INV-17'), isNull);
  });

  test('an edited bill opens its latest issued revision', () async {
    final first = await _pdf('First issue');
    final edited = await _pdf('Edited and reissued');
    await archive.saveIfAbsent(IssuedInvoiceKind.sales, 17, 'INV-17', first);
    await archive.saveRevision(IssuedInvoiceKind.sales, 17, 'INV-17', edited);

    expect(
      await archive.read(IssuedInvoiceKind.sales, 17, 'INV-17'),
      orderedEquals(edited),
    );
    expect(await archive.read(IssuedInvoiceKind.sales, 17, 'OTHER'), isNull);
  });

  test('a damaged latest revision falls back to the original issue', () async {
    final original = await _pdf('Original issue');
    await archive.saveIfAbsent(IssuedInvoiceKind.sales, 17, 'INV-17', original);
    await archive.saveRevision(
        IssuedInvoiceKind.sales, 17, 'INV-17', await _pdf('Revision'));
    final issued = Directory('${root.path}/lotus_erp/issued_invoices/sales');
    final revision = await issued
        .list(recursive: true)
        .where((entry) => entry is File && entry.path.contains('revisions'))
        .cast<File>()
        .first;
    await revision.writeAsBytes([1, 2, 3]);

    expect(await archive.read(IssuedInvoiceKind.sales, 17, 'INV-17'), original);
  });

  test('a damaged current original falls back to a valid legacy copy',
      () async {
    final legacyRoot =
        await Directory.systemTemp.createTemp('issued_invoice_legacy_');
    addTearDown(() => legacyRoot.delete(recursive: true));
    final oldArchive =
        IssuedInvoiceArchive(directoryProvider: () async => legacyRoot);
    final current = IssuedInvoiceArchive(
      directoryProvider: () async => root,
      legacyDirectoryProvider: () async => legacyRoot,
    );
    final original = await _pdf('Valid legacy original');
    await oldArchive.saveIfAbsent(
        IssuedInvoiceKind.sales, 17, 'INV-17', original);
    await archive.saveIfAbsent(
        IssuedInvoiceKind.sales, 17, 'INV-17', await _pdf('Current'));
    final currentFile =
        await Directory('${root.path}/lotus_erp/issued_invoices/sales')
            .list()
            .where((entry) => entry is File)
            .cast<File>()
            .first;
    await currentFile.writeAsBytes([1, 2, 3]);

    expect(await current.read(IssuedInvoiceKind.sales, 17, 'INV-17'), original);
  });

  test('reads an existing PDF from the previous support directory', () async {
    final legacyRoot =
        await Directory.systemTemp.createTemp('issued_invoice_legacy_');
    addTearDown(() => legacyRoot.delete(recursive: true));
    final legacy = IssuedInvoiceArchive(
      directoryProvider: () async => legacyRoot,
    );
    final current = IssuedInvoiceArchive(
      directoryProvider: () async => root,
      legacyDirectoryProvider: () async => legacyRoot,
    );
    final original = await _pdf('Issued before storage move');
    await legacy.saveIfAbsent(IssuedInvoiceKind.sales, 21, 'AJ-21', original);
    await legacy.saveMetadata(
      IssuedInvoiceKind.sales,
      21,
      'AJ-21',
      {'templateId': 'classic'},
    );

    expect(
      await current.read(IssuedInvoiceKind.sales, 21, 'AJ-21'),
      orderedEquals(original),
    );
    expect(
      await current.readMetadata(IssuedInvoiceKind.sales, 21, 'AJ-21'),
      {'templateId': 'classic'},
    );
  });
}

Future<Uint8List> _pdf(String text) async {
  final document = pw.Document()..addPage(pw.Page(build: (_) => pw.Text(text)));
  return document.save();
}
