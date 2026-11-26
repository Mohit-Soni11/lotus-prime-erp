import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('legacy sales invoice numbers migrate to compact FY series', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Reyansh Soni',
            mobile: '9304479436',
          ),
        );

    final taxBillId = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'TAX-AJ-2026-0001',
            billDate: drift.Value(DateTime(2026, 8, 1)),
            billType: const drift.Value('GST'),
            gstPricingMode: const drift.Value('GST_EXCLUSIVE'),
            totalAmount: const drift.Value(10000),
            taxableAmount: const drift.Value(10000),
            finalAmount: const drift.Value(10300),
            gstAmount: const drift.Value(300),
            status: const drift.Value('ACTIVE'),
          ),
        );
    final legacyNormalBillId = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'INV-AJ-2026-0001',
            customerId: drift.Value(customerId),
            billDate: drift.Value(DateTime(2026, 8, 2)),
            billType: const drift.Value('NORMAL'),
            totalAmount: const drift.Value(5000),
            taxableAmount: const drift.Value(5000),
            finalAmount: const drift.Value(5000),
            status: const drift.Value('ACTIVE'),
          ),
        );

    await db.into(db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'TXN-OLD-001',
            txnDate: DateTime(2026, 8, 2),
            type: 'INCOME',
            category: 'SALE',
            referenceId: const drift.Value('INV-AJ-2026-0001#CASH'),
            referenceType: const drift.Value('BILL'),
          ),
        );
    await db.into(db.customerRefundPayables).insert(
          CustomerRefundPayablesCompanion.insert(
            customerId: customerId,
            entryType: 'CREDIT',
            sourceType: 'POS_CHANGE_CREDIT',
            sourceReference:
                const drift.Value('INV-AJ-2026-0001#ACCOUNT_CREDIT'),
          ),
        );

    await db.ensureSalesInvoiceSeriesMigration();

    final taxBill = await (db.select(db.bills)
          ..where((tbl) => tbl.id.equals(taxBillId)))
        .getSingle();
    final normalBill = await (db.select(db.bills)
          ..where((tbl) => tbl.id.equals(legacyNormalBillId)))
        .getSingle();
    final cashRow = await db.select(db.cashTransactions).getSingle();
    final accountRow = await db.select(db.customerRefundPayables).getSingle();

    expect(taxBill.billNo, 'AJ-TI-26-001');
    expect(taxBill.billType, 'GST');
    expect(taxBill.documentType, 'TAX_INVOICE');
    expect(taxBill.gstPricingMode, 'GST_EXCLUSIVE');
    expect(taxBill.taxTreatment, 'TAXABLE_SUPPLY');
    expect(normalBill.billNo, 'AJ-SI-26-001');
    expect(normalBill.billType, 'NORMAL');
    expect(normalBill.documentType, 'SALES_INVOICE');
    expect(normalBill.gstPricingMode, 'GST_EXCLUSIVE');
    expect(normalBill.taxTreatment, 'NON_GST_SALE');
    expect(cashRow.referenceId, 'AJ-SI-26-001#CASH');
    expect(accountRow.sourceReference, 'AJ-SI-26-001#ACCOUNT_CREDIT');

    await db.ensureSalesInvoiceSeriesMigration();
    final stableBillNumbers = (await db.select(db.bills).get())
        .map((bill) => bill.billNo)
        .toList(growable: false);
    expect(stableBillNumbers, ['AJ-TI-26-001', 'AJ-SI-26-001']);
  });

  test('current compact invoices migrate to their matching typed series',
      () async {
    final normalBillId = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'AJ-26-007',
            billDate: drift.Value(DateTime(2026, 8, 3)),
            billType: const drift.Value('NORMAL'),
          ),
        );
    final taxBillId = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'AJ-26-008',
            billDate: drift.Value(DateTime(2026, 8, 3)),
            billType: const drift.Value('GST'),
          ),
        );
    await db.into(db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: 'TXN-COMPACT-001',
            txnDate: DateTime(2026, 8, 3),
            type: 'INCOME',
            category: 'SALE',
            referenceId: const drift.Value('AJ-26-007#CASH'),
            referenceType: const drift.Value('BILL'),
          ),
        );

    await db.ensureSalesInvoiceSeriesMigration();

    final normalBill = await (db.select(db.bills)
          ..where((table) => table.id.equals(normalBillId)))
        .getSingle();
    final taxBill = await (db.select(db.bills)
          ..where((table) => table.id.equals(taxBillId)))
        .getSingle();
    final cashRow = await db.select(db.cashTransactions).getSingle();

    expect(normalBill.billNo, 'AJ-SI-26-007');
    expect(normalBill.documentType, 'SALES_INVOICE');
    expect(taxBill.billNo, 'AJ-TI-26-008');
    expect(taxBill.documentType, 'TAX_INVOICE');
    expect(cashRow.referenceId, 'AJ-SI-26-007#CASH');
  });
}
