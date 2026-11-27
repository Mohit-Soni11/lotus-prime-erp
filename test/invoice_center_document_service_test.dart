import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/features/invoice_center/application/invoice_center_document_service.dart';
import 'package:lotus_erp/features/invoice_center/domain/invoice_center_models.dart';

void main() {
  late Directory directory;
  late IssuedInvoiceArchive archive;
  late InvoiceCenterDocumentService documents;

  InvoiceCenterRow row(
    InvoiceCenterDocumentKind kind,
    int id,
    String number,
  ) =>
      InvoiceCenterRow(
        kind: kind,
        id: id,
        number: number,
        issuedAt: DateTime(2026, 11, 24),
        customerName: 'Customer',
        mobile: '',
        customerId: null,
        metals: '',
        category: InvoiceCenterTab.regular,
        status: 'SETTLED',
        total: 100,
        paid: 100,
        due: 0,
      );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('invoice-center-test-');
    archive = IssuedInvoiceArchive(directoryProvider: () async => directory);
    documents = InvoiceCenterDocumentService(archive: archive);
  });

  tearDown(() async => directory.delete(recursive: true));

  test('reads exact saved sales, booking and cancellation PDFs', () async {
    final cases = [
      (InvoiceCenterDocumentKind.sales, IssuedInvoiceKind.sales, 'INV-001'),
      (InvoiceCenterDocumentKind.booking, IssuedInvoiceKind.booking, 'ADV-001'),
      (
        InvoiceCenterDocumentKind.cancellation,
        IssuedInvoiceKind.returnVoucher,
        'CAN-001',
      ),
    ];
    for (var index = 0; index < cases.length; index++) {
      final (kind, archiveKind, number) = cases[index];
      final bytes = Uint8List.fromList('%PDF-original-$index'.codeUnits);
      await archive.saveIfAbsent(archiveKind, index + 1, number, bytes);
      expect(await documents.readOriginal(row(kind, index + 1, number)), bytes);
    }
  });

  test('missing original returns null without creating a replacement',
      () async {
    final invoice = row(InvoiceCenterDocumentKind.sales, 12, 'INV-MISSING');
    expect(await documents.readOriginal(invoice), isNull);
    expect(await directory.list(recursive: true).toList(), isEmpty);
  });

  test('attaches a supplied original once and keeps its bytes', () async {
    final invoice = row(InvoiceCenterDocumentKind.sales, 12, 'INV-OLD');
    final original = Uint8List.fromList('%PDF-original'.codeUnits);
    final different = Uint8List.fromList('%PDF-different'.codeUnits);

    expect(await documents.attachOriginal(invoice, original), original);
    expect(await documents.attachOriginal(invoice, different), original);
    expect(await documents.readOriginal(invoice), original);
  });
}
