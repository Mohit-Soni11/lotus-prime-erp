import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/features/sales_pos/application/documents/issued_sales_pdf_loader.dart';

void main() {
  late Directory root;
  late IssuedInvoiceArchive archive;
  final original = Uint8List.fromList('%PDF-original'.codeUnits);
  final revision = Uint8List.fromList('%PDF-revised'.codeUnits);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('issued-sales-loader-');
    archive = IssuedInvoiceArchive(directoryProvider: () async => root);
  });

  tearDown(() async => root.delete(recursive: true));

  test('revision failure does not hide an existing issued PDF', () async {
    await archive.saveIfAbsent(IssuedInvoiceKind.sales, 21, 'AJ-21', original);
    final loader = IssuedSalesPdfLoader(
      archive: archive,
      synchronize: (_, __) async => throw StateError('PDF revision failed'),
    );

    expect(await loader.load(21, 'AJ-21'), original);
  });

  test('missing original does not trigger a revision', () async {
    var attempted = false;
    final loader = IssuedSalesPdfLoader(
      archive: archive,
      synchronize: (_, __) async {
        attempted = true;
        return false;
      },
    );

    expect(await loader.load(21, 'AJ-21'), isNull);
    expect(attempted, isFalse);
  });

  test('successful payment revision is the PDF returned to the viewer',
      () async {
    await archive.saveIfAbsent(IssuedInvoiceKind.sales, 21, 'AJ-21', original);
    final loader = IssuedSalesPdfLoader(
      archive: archive,
      synchronize: (_, __) async {
        await archive.saveRevision(
          IssuedInvoiceKind.sales,
          21,
          'AJ-21',
          revision,
        );
        return true;
      },
    );

    expect(await loader.load(21, 'AJ-21'), revision);
    expect(await archive.read(IssuedInvoiceKind.sales, 21, 'AJ-21'), revision);
  });
}
