import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_source_document_service.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';

void main() {
  test('opens original archived invoice bytes for a linked payment', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final directory = await Directory.systemTemp.createTemp('day-book-pdf-');
    addTearDown(() async {
      await db.close();
      await directory.delete(recursive: true);
    });
    final billId = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'INV-ARCHIVE-1',
          finalAmount: const drift.Value(100),
        ));
    final archive =
        IssuedInvoiceArchive(directoryProvider: () async => directory);
    final original = Uint8List.fromList('%PDF-1.4 original bytes'.codeUnits);
    await archive.saveIfAbsent(
        IssuedInvoiceKind.sales, billId, 'INV-ARCHIVE-1', original);
    final entry = DayBookMoneyEntry(
      date: DateTime(2026, 6, 25),
      amount: 100,
      incoming: true,
      isCash: true,
      category: 'SALE',
      paymentMode: 'CASH',
      transactionId: 'C-1',
      referenceType: 'BILL',
      referenceId: 'INV-ARCHIVE-1#CASH',
    );
    final service = DayBookSourceDocumentService(db, archive: archive);
    expect(await service.readOriginalSalePdf(entry), original);
  });
}
