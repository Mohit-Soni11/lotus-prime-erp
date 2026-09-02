import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('customer profile reads saved Girvi records from girviLoans', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Test Customer',
            mobile: '9999999999',
          ),
        );

    await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV/2026/00001',
            customerId: customerId,
            itemDescription: 'Gold ring',
            grossWeight: const Value(8.25),
            loanAmount: const Value(25000),
            interestRate: const Value(2),
            startDate: Value(DateTime(2026, 6, 9)),
          ),
        );
    await db.into(db.loans).insert(
          LoansCompanion.insert(
            loanNo: 'OLD/2025/00001',
            customerId: customerId,
            itemDesc: 'Legacy chain',
            startDate: Value(DateTime(2025, 6, 9)),
          ),
        );

    final profile =
        await CustomerProfileRepository(db: db).fetchProfile(customerId);

    expect(profile == null, isFalse);
    expect(profile!.loans, hasLength(2));
    expect(profile.loans.first.loanNo, 'GRV/2026/00001');
    expect(profile.loans.first.itemDesc, 'Gold ring');
    expect(profile.loans.first.loanAmount, 25000);
    expect(profile.loans.last.loanNo, 'OLD/2025/00001');
    expect(profile.activeLoans, 2);
  });

  test('customer profile marks bills with posted return vouchers', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Reyansh Soni',
            mobile: '9304479436',
          ),
        );

    final billId = await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'AJ-26-008',
            customerId: Value(customerId),
            customerName: const Value('Reyansh Soni'),
            mobile: const Value('9304479436'),
            finalAmount: const Value(49385.07),
            paidAmount: const Value(45000),
            dueAmount: const Value(0),
            paymentStatus: const Value('PAID'),
            billDate: Value(DateTime(2026, 8, 22)),
            status: const Value('ACTIVE'),
          ),
        );

    await db.into(db.billItems).insert(
          BillItemsCompanion.insert(
            billId: billId,
            lineNo: const Value(1),
            metalType: const Value('GOLD'),
            itemName: 'NOSE PIN',
            quantityUnitCode: const Value('PCS'),
            netWeight: const Value(1.269),
            itemTotal: const Value(18050),
          ),
        );
    await db.into(db.billItems).insert(
          BillItemsCompanion.insert(
            billId: billId,
            lineNo: const Value(2),
            metalType: const Value('SILVER'),
            itemName: 'PAYAL',
            quantityUnitCode: const Value('PAIR'),
            netWeight: const Value(100),
            itemTotal: const Value(24000),
          ),
        );

    await db.ensureReturnReversalSchema();
    final createdAt = DateTime(2026, 9, 2, 11, 32).millisecondsSinceEpoch;
    await db.customStatement(
      '''
      INSERT INTO return_vouchers (
        voucher_no,
        operation_type,
        source_type,
        source_id,
        source_number,
        customer_id,
        customer_name,
        mobile,
        settlement_mode,
        original_total_amount,
        return_value,
        status,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        'SR-26-00001',
        'RETURN',
        'SALES_INVOICE',
        billId,
        'AJ-26-008',
        customerId,
        'Reyansh Soni',
        '9304479436',
        'CASH_REFUND',
        49385.07,
        18050,
        'POSTED',
        createdAt,
      ],
    );
    final voucherId =
        (await db.customSelect('SELECT last_insert_rowid() AS id').getSingle())
            .read<int>('id');

    await db.customStatement(
      '''
      INSERT INTO return_voucher_lines (
        return_voucher_id,
        source_type,
        source_id,
        source_number,
        source_line_no,
        stock_disposition,
        metal_type,
        item_description,
        quantity,
        quantity_unit_code,
        sold_net_weight,
        received_net_weight,
        rate,
        sold_item_value,
        adjusted_item_value,
        metal_return_amount,
        line_return_value,
        status,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        voucherId,
        'SALES_INVOICE',
        billId,
        'AJ-26-008',
        1,
        'ADD_STOCK',
        'GOLD',
        'NOSE PIN',
        1,
        'PCS',
        1.269,
        1.269,
        12700,
        18050,
        18050,
        16116,
        18050,
        'POSTED',
        createdAt,
      ],
    );

    final profile =
        await CustomerProfileRepository(db: db).fetchProfile(customerId);

    expect(profile == null, isFalse);
    final bill = profile!.bills.single;
    expect(bill.dueAmount, 0);
    expect(bill.paymentLabel, 'SETTLED');
    expect(bill.lifecycleLabel, 'PARTIAL RETURN');
    expect(bill.lineCount, 2);
    expect(bill.returnedLineCount, 1);
    expect(bill.returnProgressLabel, '1/2 ITEMS');
    expect(bill.returnedAmount, 18050);
    expect(bill.returnVoucherNo, 'SR-26-00001');
    expect(bill.linkedDocumentSummary, 'Linked SR-26-00001');
    expect(bill.linkedDocuments, hasLength(1));
    expect(bill.linkedDocuments.single.documentTitle, 'Sales Return Voucher');
    expect(bill.linkedDocuments.single.sourceNumber, 'AJ-26-008');
    expect(bill.linkedDocuments.single.lineCount, 1);
    expect(bill.linkedDocuments.single.returnValue, 18050);
    expect(bill.linkedDocuments.single.statusLabel, 'POSTED');
  });
}
