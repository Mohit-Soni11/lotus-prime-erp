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
}

Future<Uint8List> _pdf(String text) async {
  final document = pw.Document()..addPage(pw.Page(build: (_) => pw.Text(text)));
  return document.save();
}
