import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../../../core/documents/issued_invoice_archive.dart';
import '../../../database/db/app_database.dart';
import '../../../models/reports/day_book/day_book_money_flow.dart';

class DayBookSourceDocumentService {
  const DayBookSourceDocumentService(this._db,
      {IssuedInvoiceArchive archive = const IssuedInvoiceArchive()})
      : _archive = archive;

  final AppDatabase _db;
  final IssuedInvoiceArchive _archive;

  bool supportsOriginalPdf(DayBookMoneyEntry entry) {
    final type = entry.referenceType?.toUpperCase();
    return type == 'BILL' &&
        entry.referenceId != null &&
        entry.referenceId!.trim().isNotEmpty;
  }

  Future<Uint8List?> readOriginalSalePdf(DayBookMoneyEntry entry) async {
    if (!supportsOriginalPdf(entry)) return null;
    final billNo = entry.referenceId!.split('#').first.trim();
    if (billNo.isEmpty) return null;
    final bill = await (_db.select(_db.bills)
          ..where((row) => row.billNo.equals(billNo)))
        .getSingleOrNull();
    if (bill == null) return null;
    return _archive.read(IssuedInvoiceKind.sales, bill.id, bill.billNo);
  }
}
