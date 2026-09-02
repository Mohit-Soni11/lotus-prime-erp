import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/finance/due_collection_entry/due_collection_entry_model.dart';
import 'package:lotus_erp/repositories/customer/customer_list_repository.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';
import 'package:lotus_erp/repositories/finance/due_collection_entry_repository.dart';
import 'package:lotus_erp/repositories/finance/due_receipt_history_repository.dart';
import 'package:lotus_erp/repositories/finance/due_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('cash due collection clears the bill across finance and customer flows',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final customerId = await _insertCustomer(db);
    final billId = await _insertDueBill(
      db,
      customerId: customerId,
      billNo: 'AJ-26-DUE-001',
      finalAmount: 8000,
      paidAmount: 7000,
      dueAmount: 1000,
    );

    try {
      final collectionRepo = DueCollectionEntryRepository(db: db);
      final dueReportRepo = DueReportRepository(db: db);
      final receiptRepo = DueReceiptHistoryRepository(db: db);
      final profileRepo = CustomerProfileRepository(db: db);
      final customerListRepo = CustomerListRepository(db: db);

      expect(
        (await collectionRepo.fetchDueBills()).map((bill) => bill.billNo),
        contains('AJ-26-DUE-001'),
      );

      final result = await collectionRepo.saveCollection(
        billId: billId,
        amount: 1000,
        discountAmount: 0,
        mode: DueCollectionPaymentMode.cash,
        bankAccountId: null,
        nextPromiseDate: null,
        notes: 'Final settlement',
      );

      expect(result.success, isTrue);
      expect(result.receiptNo, startsWith('TXN-'));

      final bill = await (db.select(db.bills)
            ..where((tbl) => tbl.id.equals(billId)))
          .getSingle();
      expect(bill.paidAmount, 8000);
      expect(bill.dueAmount, 0);
      expect(bill.paymentStatus, 'PAID');
      expect(bill.promiseDate, isNull);

      expect(
        (await collectionRepo.fetchDueBills()).map((item) => item.billNo),
        isNot(contains('AJ-26-DUE-001')),
      );
      expect(
        (await dueReportRepo.fetchDueBills()).map((item) => item.billNo),
        isNot(contains('AJ-26-DUE-001')),
      );

      final receipts = await receiptRepo.fetchReceipts();
      expect(receipts, hasLength(1));
      expect(receipts.single.billNo, 'AJ-26-DUE-001');
      expect(receipts.single.amount, 1000);
      expect(receipts.single.currentDue, 0);
      expect(receipts.single.channelLabel, 'Cash Book');

      final profile = await profileRepo.fetchProfile(customerId);
      expect(profile, isNotNull);
      expect(profile!.outstanding, 0);
      expect(profile.dues, isEmpty);
      expect(profile.bills.single.dueAmount, 0);

      final customers = await customerListRepo.getAllCustomers();
      expect(customers.single.dueAmount, 0);

      final cashRows = await db.select(db.cashTransactions).get();
      expect(cashRows, hasLength(1));
      expect(cashRows.single.category, 'DUE_COLLECTION');
      expect(cashRows.single.referenceId, 'AJ-26-DUE-001#DUE#CASH');
    } finally {
      await db.close();
    }
  });

  test('partial due collection with discount keeps remaining due synchronized',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final customerId = await _insertCustomer(db, mobile: '9304479437');
    final promiseDate = DateTime(2026, 9, 5);
    final billId = await _insertDueBill(
      db,
      customerId: customerId,
      billNo: 'AJ-26-DUE-002',
      finalAmount: 8000,
      paidAmount: 5000,
      dueAmount: 3000,
    );

    try {
      final collectionRepo = DueCollectionEntryRepository(db: db);
      final dueReportRepo = DueReportRepository(db: db);
      final profileRepo = CustomerProfileRepository(db: db);
      final customerListRepo = CustomerListRepository(db: db);

      final result = await collectionRepo.saveCollection(
        billId: billId,
        amount: 1000,
        discountAmount: 500,
        mode: DueCollectionPaymentMode.cash,
        bankAccountId: null,
        nextPromiseDate: promiseDate,
        notes: 'Waiver approved',
      );

      expect(result.success, isTrue);

      final bill = await (db.select(db.bills)
            ..where((tbl) => tbl.id.equals(billId)))
          .getSingle();
      expect(bill.paidAmount, 6000);
      expect(bill.discount, 500);
      expect(bill.finalAmount, 7500);
      expect(bill.dueAmount, 1500);
      expect(bill.paymentStatus, 'PARTIAL');
      expect(bill.promiseDate, promiseDate);

      final collectionBills = await collectionRepo.fetchDueBills();
      expect(collectionBills.single.billNo, 'AJ-26-DUE-002');
      expect(collectionBills.single.dueAmount, 1500);

      final dueReportBills = await dueReportRepo.fetchDueBills();
      expect(dueReportBills.single.billNo, 'AJ-26-DUE-002');
      expect(dueReportBills.single.dueAmount, 1500);

      final profile = await profileRepo.fetchProfile(customerId);
      expect(profile, isNotNull);
      expect(profile!.outstanding, 1500);
      expect(profile.dues.single.dueAmount, 1500);

      final customers = await customerListRepo.getAllCustomers();
      expect(customers.single.dueAmount, 1500);
    } finally {
      await db.close();
    }
  });

  test('paid bill with return-adjusted due is hidden across due ledgers',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final customerId = await _insertCustomer(db, mobile: '9304479438');
    await _insertDueBill(
      db,
      customerId: customerId,
      billNo: 'AJ-26-RETURN-CLEAR',
      finalAmount: 49385.07,
      paidAmount: 45000,
      dueAmount: 0,
      paymentStatus: 'PAID',
    );

    try {
      final collectionRepo = DueCollectionEntryRepository(db: db);
      final dueReportRepo = DueReportRepository(db: db);
      final profileRepo = CustomerProfileRepository(db: db);
      final customerListRepo = CustomerListRepository(db: db);

      expect(
        (await collectionRepo.fetchDueBills()).map((bill) => bill.billNo),
        isNot(contains('AJ-26-RETURN-CLEAR')),
      );
      expect(
        (await dueReportRepo.fetchDueBills()).map((bill) => bill.billNo),
        isNot(contains('AJ-26-RETURN-CLEAR')),
      );

      final profile = await profileRepo.fetchProfile(customerId);
      expect(profile, isNotNull);
      expect(profile!.outstanding, 0);
      expect(profile.dues, isEmpty);
      expect(profile.bills.single.dueAmount, 0);
      expect(profile.bills.single.paymentLabel, 'SETTLED');

      final customers = await customerListRepo.getAllCustomers();
      expect(customers.single.dueAmount, 0);
    } finally {
      await db.close();
    }
  });

  test('partially returned bill with remaining due stays in due ledgers',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final customerId = await _insertCustomer(db, mobile: '9304479439');
    await _insertDueBill(
      db,
      customerId: customerId,
      billNo: 'AJ-26-RETURN-DUE',
      finalAmount: 49385.07,
      paidAmount: 30000,
      dueAmount: 2500,
      paymentStatus: 'PARTIAL',
      status: 'PARTIALLY_RETURNED',
    );

    try {
      final collectionRepo = DueCollectionEntryRepository(db: db);
      final dueReportRepo = DueReportRepository(db: db);
      final profileRepo = CustomerProfileRepository(db: db);
      final customerListRepo = CustomerListRepository(db: db);

      final collectionBills = await collectionRepo.fetchDueBills();
      expect(collectionBills.single.billNo, 'AJ-26-RETURN-DUE');
      expect(collectionBills.single.dueAmount, 2500);

      final dueReportBills = await dueReportRepo.fetchDueBills();
      expect(dueReportBills.single.billNo, 'AJ-26-RETURN-DUE');
      expect(dueReportBills.single.dueAmount, 2500);

      final profile = await profileRepo.fetchProfile(customerId);
      expect(profile, isNotNull);
      expect(profile!.outstanding, 2500);
      expect(profile.dues.single.dueAmount, 2500);

      final customers = await customerListRepo.getAllCustomers();
      expect(customers.single.dueAmount, 2500);
    } finally {
      await db.close();
    }
  });
}

Future<int> _insertCustomer(
  AppDatabase db, {
  String mobile = '9304479436',
}) {
  return db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: 'REYANSH SONI',
          mobile: mobile,
          city: const drift.Value('Patna'),
          addressLine1: const drift.Value('East Lakshmi Nagar'),
          state: const drift.Value('Bihar'),
          pincode: const drift.Value('800027'),
        ),
      );
}

Future<int> _insertDueBill(
  AppDatabase db, {
  required int customerId,
  required String billNo,
  required double finalAmount,
  required double paidAmount,
  required double dueAmount,
  String paymentStatus = 'PARTIAL',
  String status = 'ACTIVE',
}) {
  return db.into(db.bills).insert(
        BillsCompanion.insert(
          billNo: billNo,
          customerId: drift.Value(customerId),
          customerName: const drift.Value('REYANSH SONI'),
          mobile: const drift.Value('9304479436'),
          billType: const drift.Value('GST'),
          paymentStatus: drift.Value(paymentStatus),
          totalAmount: drift.Value(finalAmount),
          finalAmount: drift.Value(finalAmount),
          paidAmount: drift.Value(paidAmount),
          cashPaid: drift.Value(paidAmount),
          dueAmount: drift.Value(dueAmount),
          billDate: drift.Value(DateTime(2026, 8, 23, 10)),
          status: drift.Value(status),
        ),
      );
}
