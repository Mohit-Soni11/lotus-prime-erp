import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/core/documents/issued_invoice_archive.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/sales_pos/application/documents/sales_invoice_payment_revision_service.dart';
import 'package:lotus_erp/models/finance/due_collection_entry/due_collection_entry_model.dart';
import 'package:lotus_erp/repositories/finance/due_collection_entry_repository.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('later collection archives a paid revision and preserves issued PDF',
      () async {
    final root = await Directory.systemTemp.createTemp('sales_payment_pdf_');
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => root.path,
    );
    final archive = IssuedInvoiceArchive(directoryProvider: () async => root);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      await AppDatabase().close();
      await root.delete(recursive: true);
    });

    final billId = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'AJ-26-099',
            customerName: const drift.Value('Test Customer'),
            mobile: const drift.Value('9999999999'),
            billType: const drift.Value('NORMAL'),
            totalAmount: const drift.Value(1000),
            finalAmount: const drift.Value(1000),
            paidAmount: const drift.Value(800),
            cashPaid: const drift.Value(800),
            dueAmount: const drift.Value(200),
            paymentStatus: const drift.Value('PARTIAL'),
          ),
        );
    await db.into(db.billItems).insert(
          BillItemsCompanion.insert(
            billId: billId,
            itemName: 'Gold ring',
            itemTotal: const drift.Value(1000),
            rate: const drift.Value(1000),
            netWeight: const drift.Value(1),
          ),
        );
    final original = await (pw.Document()
          ..addPage(pw.Page(build: (_) => pw.Text('Original invoice'))))
        .save();
    await archive.saveIfAbsent(
      IssuedInvoiceKind.sales,
      billId,
      'AJ-26-099',
      original,
    );
    await archive.saveMetadata(
      IssuedInvoiceKind.sales,
      billId,
      'AJ-26-099',
      {
        'templateId': 'lotus-classic',
        'format': 'a4',
        'paidAmount': 800,
        'dueAmount': 200,
      },
    );

    final result = await DueCollectionEntryRepository(
      db: db,
      issuedInvoiceArchive: archive,
    ).saveCollection(
      billId: billId,
      amount: 200,
      discountAmount: 0,
      mode: DueCollectionPaymentMode.cash,
      bankAccountId: null,
      nextPromiseDate: null,
      notes: 'Paid in full',
    );
    expect(result.success, isTrue);
    expect(result.message, isNot(contains('pending')));
    final service = SalesInvoicePaymentRevisionService(
      database: db,
      archive: archive,
    );
    final revised = await archive.read(
      IssuedInvoiceKind.sales,
      billId,
      'AJ-26-099',
    );
    expect(revised, isNotNull);
    expect(revised, isNot(orderedEquals(original)));
    expect(
      await archive.readMetadata(
        IssuedInvoiceKind.sales,
        billId,
        'AJ-26-099',
      ),
      containsPair('dueAmount', 0),
    );
    expect(await service.synchronize(billId, 'AJ-26-099'), isFalse);

    await archive.saveMetadata(
      IssuedInvoiceKind.sales,
      billId,
      'AJ-26-099',
      {
        'templateId': 'lotus-classic',
        'format': 'a4',
        'paidAmount': 1000,
        'dueAmount': 0,
      },
    );
    expect(await service.synchronize(billId, 'AJ-26-099'), isTrue);
    expect(await service.synchronize(billId, 'AJ-26-099'), isFalse);

    final legacyBillId = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'AJ-26-098',
            customerName: const drift.Value('Test Customer'),
            billType: const drift.Value('NORMAL'),
            totalAmount: const drift.Value(1000),
            finalAmount: const drift.Value(1000),
            paidAmount: const drift.Value(1000),
            cashPaid: const drift.Value(800),
            dueAmount: const drift.Value(0),
            paymentStatus: const drift.Value('PAID'),
          ),
        );
    await db.into(db.billItems).insert(
          BillItemsCompanion.insert(
            billId: legacyBillId,
            itemName: 'Gold ring',
            itemTotal: const drift.Value(1000),
            rate: const drift.Value(1000),
            netWeight: const drift.Value(1),
          ),
        );
    await archive.saveIfAbsent(
      IssuedInvoiceKind.sales,
      legacyBillId,
      'AJ-26-098',
      original,
    );
    expect(await service.synchronize(legacyBillId, 'AJ-26-098'), isTrue);
    expect(await service.synchronize(legacyBillId, 'AJ-26-098'), isFalse);
  });
}
