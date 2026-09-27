import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:lotus_erp/core/logging/app_logger.dart';

class GirviInvoiceDocumentStore {
  const GirviInvoiceDocumentStore();

  Future<Uint8List?> readInvoice({
    required int? loanId,
    required String ticketNo,
  }) async {
    try {
      final file = await _invoiceFile(loanId: loanId, ticketNo: ticketNo);
      if (await file.exists()) return file.readAsBytes();

      if (loanId == null) {
        final legacyFile = await _legacyInvoiceFile(ticketNo);
        if (await legacyFile.exists()) return legacyFile.readAsBytes();
      }
      return null;
    } catch (error) {
      AppLogger.debug('Girvi invoice snapshot read failed: $error');
      return null;
    }
  }

  Future<File?> saveInvoice({
    required int? loanId,
    required String ticketNo,
    required Uint8List bytes,
  }) async {
    try {
      final file = await _invoiceFile(loanId: loanId, ticketNo: ticketNo);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (error) {
      AppLogger.debug('Girvi invoice snapshot save failed: $error');
      return null;
    }
  }

  Future<File> _invoiceFile({
    required int? loanId,
    required String ticketNo,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final safeLoan = loanId == null ? 'unlinked' : 'loan_$loanId';
    final safeTicket = ticketNo.trim().replaceAll(
          RegExp(r'[^A-Za-z0-9_-]+'),
          '_',
        );
    return File(
      p.join(
        directory.path,
        'lotus_erp',
        'girvi_documents',
        'invoices',
        'girvi_invoice_${safeLoan}_$safeTicket.pdf',
      ),
    );
  }

  Future<File> _legacyInvoiceFile(String ticketNo) async {
    final directory = await getApplicationSupportDirectory();
    final safeTicket = ticketNo.trim().replaceAll(
          RegExp(r'[^A-Za-z0-9_-]+'),
          '_',
        );
    return File(
      p.join(
        directory.path,
        'lotus_erp',
        'girvi_documents',
        'invoices',
        'girvi_invoice_$safeTicket.pdf',
      ),
    );
  }
}
