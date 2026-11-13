import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/logic/booking_advance/booking_issued_pdf_loader.dart';

void main() {
  test('booking PDF loader reads the issued PDF linked to its order', () async {
    final directory = await Directory.systemTemp.createTemp('booking_pdf_');
    addTearDown(() => directory.delete(recursive: true));
    final archive =
        IssuedInvoiceArchive(directoryProvider: () async => directory);
    final issuedBytes =
        Uint8List.fromList('%PDF-1.7 booking receipt'.codeUnits);
    await archive.saveIfAbsent(
      IssuedInvoiceKind.booking,
      42,
      'AJ-BK-26-0042',
      issuedBytes,
    );

    final loaded = await BookingIssuedPdfLoader(archive: archive).load(
      orderId: 42,
      bookingNumber: 'AJ-BK-26-0042',
    );

    expect(loaded, issuedBytes);
  });
}
