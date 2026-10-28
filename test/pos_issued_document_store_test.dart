import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/features/sales_pos/application/documents/pos_issued_document_store.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('the issued PDF is the exact preview snapshot', () async {
    final root = await Directory.systemTemp.createTemp('pos_issued_store_');
    addTearDown(() => root.delete(recursive: true));
    final archive = IssuedInvoiceArchive(directoryProvider: () async => root);
    final store = PosIssuedDocumentStore(archive: archive);
    final preview = await (pw.Document()
          ..addPage(pw.Page(build: (_) => pw.Text('Final POS preview'))))
        .save();

    final issued = await store.issue(
      billId: 21,
      billNo: 'AJ-26-021',
      previewBytes: preview,
      revision: false,
      templateId: 'lotus-classic',
      format: 'a4',
      paidAmount: 100,
      dueAmount: 50,
    );

    expect(issued, orderedEquals(preview));
    expect(
      await store.require(billId: 21, billNo: 'AJ-26-021'),
      orderedEquals(preview),
    );
    expect(
      await archive.readMetadata(IssuedInvoiceKind.sales, 21, 'AJ-26-021'),
      containsPair('templateId', 'lotus-classic'),
    );
  });
}
