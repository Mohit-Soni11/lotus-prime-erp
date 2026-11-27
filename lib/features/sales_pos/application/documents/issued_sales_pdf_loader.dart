import 'dart:typed_data';

import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

import 'sales_invoice_payment_revision_service.dart';

class IssuedSalesPdfLoader {
  const IssuedSalesPdfLoader({
    this.archive = const IssuedInvoiceArchive(),
    this.synchronize,
  });

  final IssuedInvoiceArchive archive;
  final Future<bool> Function(int billId, String billNo)? synchronize;

  Future<Uint8List?> load(int billId, String billNo) async {
    final issued = await archive.read(IssuedInvoiceKind.sales, billId, billNo);
    if (issued == null) return null;

    try {
      final updated = await (synchronize?.call(billId, billNo) ??
          SalesInvoicePaymentRevisionService(archive: archive)
              .synchronize(billId, billNo));
      if (updated) {
        return await archive.read(IssuedInvoiceKind.sales, billId, billNo) ??
            issued;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Sales PDF revision retry failed; opening the saved issue.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return issued;
  }
}
