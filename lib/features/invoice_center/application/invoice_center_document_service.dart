import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';

import '../domain/invoice_center_models.dart';

class InvoiceCenterDocumentService {
  const InvoiceCenterDocumentService({
    IssuedInvoiceArchive archive = const IssuedInvoiceArchive(),
  }) : _archive = archive;

  final IssuedInvoiceArchive _archive;

  Future<Uint8List?> readOriginal(InvoiceCenterRow row) => _archive.read(
        switch (row.kind) {
          InvoiceCenterDocumentKind.sales => IssuedInvoiceKind.sales,
          InvoiceCenterDocumentKind.booking => IssuedInvoiceKind.booking,
          InvoiceCenterDocumentKind.cancellation =>
            IssuedInvoiceKind.returnVoucher,
        },
        row.id,
        row.number,
      );

  Future<Uint8List?> attachOriginal(
    InvoiceCenterRow row,
    Uint8List bytes,
  ) async {
    final kind = switch (row.kind) {
      InvoiceCenterDocumentKind.sales => IssuedInvoiceKind.sales,
      InvoiceCenterDocumentKind.booking => IssuedInvoiceKind.booking,
      InvoiceCenterDocumentKind.cancellation => IssuedInvoiceKind.returnVoucher,
    };
    await _archive.saveIfAbsent(kind, row.id, row.number, bytes);
    return _archive.read(kind, row.id, row.number);
  }

  Future<bool> printOriginal(InvoiceCenterRow row, Uint8List bytes) =>
      Printing.layoutPdf(
        name: fileName(row),
        onLayout: (_) async => bytes,
      );

  Future<bool> shareOriginal(InvoiceCenterRow row, Uint8List bytes) =>
      Printing.sharePdf(bytes: bytes, filename: fileName(row));

  String fileName(InvoiceCenterRow row) {
    final safeNumber = row.number.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return '$safeNumber.pdf';
  }
}
