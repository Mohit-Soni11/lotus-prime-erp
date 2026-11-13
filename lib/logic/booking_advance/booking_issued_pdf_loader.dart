import 'dart:typed_data';

import '../../core/documents/issued_invoice_archive.dart';
import 'booking_invoice_preview_controller.dart';

/// Opens the issued booking document first and rebuilds legacy PDFs if needed.
class BookingIssuedPdfLoader {
  const BookingIssuedPdfLoader({
    this.archive = const IssuedInvoiceArchive(),
    this.previewControllerFactory,
  });

  final IssuedInvoiceArchive archive;
  final BookingInvoicePreviewController Function(int orderId)?
      previewControllerFactory;

  Future<Uint8List?> load({
    required int orderId,
    required String bookingNumber,
  }) async {
    final issued = await archive.read(
      IssuedInvoiceKind.booking,
      orderId,
      bookingNumber,
    );
    if (issued != null) return issued;

    final controller = previewControllerFactory?.call(orderId) ??
        BookingInvoicePreviewController(orderIds: [orderId]);
    try {
      await controller.load();
      final bytes = controller.pdfBytes;
      if (bytes != null) IssuedInvoiceArchive.validatePdf(bytes);
      return bytes;
    } finally {
      controller.dispose();
    }
  }
}
