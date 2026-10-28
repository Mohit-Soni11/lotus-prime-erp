import 'dart:typed_data';

import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';

/// The issued sales document is the PDF snapshot approved in the POS preview.
class PosIssuedDocumentStore {
  const PosIssuedDocumentStore({
    IssuedInvoiceArchive archive = const IssuedInvoiceArchive(),
  }) : _archive = archive;

  final IssuedInvoiceArchive _archive;

  Future<Uint8List> issue({
    required int billId,
    required String billNo,
    required Uint8List previewBytes,
    required bool revision,
  }) async {
    if (revision) {
      await _archive.saveRevision(
        IssuedInvoiceKind.sales,
        billId,
        billNo,
        previewBytes,
      );
    } else {
      await _archive.saveIfAbsent(
        IssuedInvoiceKind.sales,
        billId,
        billNo,
        previewBytes,
      );
    }
    return require(billId: billId, billNo: billNo);
  }

  Future<Uint8List?> read({
    required int billId,
    required String billNo,
  }) =>
      _archive.read(IssuedInvoiceKind.sales, billId, billNo);

  Future<Uint8List> require({
    required int billId,
    required String billNo,
  }) async {
    final bytes = await read(billId: billId, billNo: billNo);
    if (bytes == null) {
      throw StateError('The original issued sales PDF is unavailable.');
    }
    return bytes;
  }
}
