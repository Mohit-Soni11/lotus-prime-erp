import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/repositories/customer/customer_list_repository.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('customer deletion removes an unused profile', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Unused Customer',
            mobile: '9000000091',
          ),
        );

    final result =
        await CustomerProfileRepository(db: db).deleteCustomer(customerId);
    final remaining = await (db.select(db.customers)
          ..where((row) => row.id.equals(customerId)))
        .getSingleOrNull();

    expect(result.deleted, isTrue);
    expect(remaining, equals(null));
  });

  test('customer deletion preserves a profile with a sales bill', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Sales Customer',
            mobile: '9000000092',
          ),
        );
    await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'AJ-26-091',
            customerId: Value(customerId),
          ),
        );

    final result =
        await CustomerProfileRepository(db: db).deleteCustomer(customerId);
    final remaining = await (db.select(db.customers)
          ..where((row) => row.id.equals(customerId)))
        .getSingleOrNull();

    expect(result.deleted, isFalse);
    expect(result.message, contains('sales invoice'));
    expect(remaining?.id, customerId);
  });

  test('profile gender uses saved customer data, never the name', () async {
    final unknownId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Asha', mobile: '9000000011'),
        );
    final femaleId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Zara',
            mobile: '9000000012',
            gender: const Value('Female'),
          ),
        );

    final repository = CustomerProfileRepository(db: db);
    final unknown = await repository.fetchProfile(unknownId);
    final female = await repository.fetchProfile(femaleId);

    expect(unknown!.gender.name, 'unknown');
    expect(female!.gender.name, 'female');
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

  test('Girvi activity uses payment date and funded tickets are not editable',
      () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Girvi Customer',
            mobile: '9000000088',
          ),
        );
    final loanId = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-ACTIVITY-1',
            customerId: customerId,
            itemDescription: 'Gold ring',
            loanAmount: const Value(25000),
            interestRate: const Value(2),
            startDate: Value(DateTime(2026, 8, 1)),
            lastInterestPaidDate: Value(DateTime(2026, 9, 1)),
          ),
        );
    final repository = CustomerProfileRepository(db: db);
    var loan = (await repository.fetchProfile(customerId))!.loans.single;
    expect(loan.canEditGirvi, isTrue);
    expect(loan.interestPaymentCount, 0);

    await db.into(db.girviPayments).insert(
          GirviPaymentsCompanion.insert(
            girviId: loanId,
            paymentType: GirviPaymentType.interest.dbValue,
            paymentDate: Value(DateTime(2026, 10, 29)),
            amount: const Value(500),
          ),
        );
    await db.into(db.girviDisbursements).insert(
          GirviDisbursementsCompanion.insert(
            girviId: loanId,
            sequenceNo: 1,
            mode: 'CASH',
            displayLabel: 'Cash',
            amount: 25000,
          ),
        );

    loan = (await repository.fetchProfile(customerId))!.loans.single;
    expect(loan.interestPaymentCount, 1);
    expect(loan.lastInterestPaymentAt, DateTime(2026, 10, 29));
    expect(loan.lastInterestPaidDate, DateTime(2026, 9, 1));
    expect(loan.canEditGirvi, isFalse);
  });

  test('Girvi ledger separates capital given from active principal', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
              name: 'Girvi Customer', mobile: '9000000099'),
        );
    final loanId = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-CAPITAL-1',
            customerId: customerId,
            itemDescription: 'Gold chain',
            loanAmount: const Value(25000),
            interestRate: const Value(2),
            startDate: Value(DateTime(2026, 9, 1)),
          ),
        );
    await db.into(db.girviPayments).insert(
          GirviPaymentsCompanion.insert(
            girviId: loanId,
            paymentType: GirviPaymentType.partialPrincipal.dbValue,
            amount: const Value(5000),
          ),
        );

    final profile =
        await CustomerProfileRepository(db: db).fetchProfile(customerId);
    expect(profile!.totalLoanAmount, 30000);
    expect(profile.totalActiveLoanAmount, 25000);
  });

  test('customer profile and list count every open Girvi status consistently',
      () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Reyansh Soni',
            mobile: '9304479436',
          ),
        );

    Future<void> insertGirvi({
      required String ticketNo,
      required GirviStatus status,
      required DateTime startDate,
      double amount = 10000,
    }) {
      return db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: ticketNo,
              customerId: customerId,
              itemDescription: 'Gold chain',
              grossWeight: const Value(10),
              loanAmount: Value(amount),
              interestRate: const Value(5),
              startDate: Value(startDate),
              status: Value(status.dbValue),
            ),
          );
    }

    await insertGirvi(
      ticketNo: 'GRV-0006',
      status: GirviStatus.released,
      startDate: DateTime(2026, 9, 20),
      amount: 6000,
    );
    await insertGirvi(
      ticketNo: 'GRV-0005',
      status: GirviStatus.overdue,
      startDate: DateTime(2026, 9, 18),
      amount: 5000,
    );
    await insertGirvi(
      ticketNo: 'GRV-0008',
      status: GirviStatus.active,
      startDate: DateTime(2026, 9, 19),
      amount: 8000,
    );
    await insertGirvi(
      ticketNo: 'GRV-0007',
      status: GirviStatus.readyForDelivery,
      startDate: DateTime(2026, 9, 21),
      amount: 7000,
    );

    final profile =
        await CustomerProfileRepository(db: db).fetchProfile(customerId);
    final customers = await CustomerListRepository(db: db).getAllCustomers();
    final customer = customers.singleWhere((c) => c.id == customerId);

    expect(profile, isNot(null));
    expect(profile!.loans.map((loan) => loan.loanNo), [
      'GRV-0008',
      'GRV-0007',
      'GRV-0005',
      'GRV-0006',
    ]);
    expect(profile.activeLoans, 3);
    expect(profile.completedLoans, 1);
    expect(profile.totalActiveLoanAmount, 20000);
    expect(customer.activeGirviCount, 3);
  });

  test('customer profile includes active booking advance orders', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Reyansh Soni',
            mobile: '9304479436',
          ),
        );

    final pendingOrderId = await db.into(db.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'AJ-BK-26-0001',
            customerId: customerId,
            itemName: 'Gold Ring',
            metalType: const Value('GOLD'),
            purity: const Value('22KT'),
            approxWeight: const Value(10),
            bookingType: const Value('LOCKED'),
            lockedRate: const Value(6500),
            status: const Value('PENDING'),
            deliveryDate: Value(DateTime(2026, 9, 30)),
            createdAt: Value(DateTime(2026, 9, 8, 10)),
          ),
        );
    final readyOrderId = await db.into(db.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'AJ-BK-26-0002',
            customerId: customerId,
            itemName: 'Silver Chain',
            metalType: const Value('SILVER'),
            purity: const Value('925'),
            approxWeight: const Value(50),
            bookingType: const Value('OPEN'),
            lockedRate: const Value(0),
            status: const Value('READY'),
            createdAt: Value(DateTime(2026, 9, 9, 10)),
          ),
        );
    final deliveredOrderId = await db.into(db.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'AJ-BK-26-0003',
            customerId: customerId,
            itemName: 'Delivered Ring',
            status: const Value('DELIVERED'),
          ),
        );

    await db.into(db.orderAdvances).insert(
          OrderAdvancesCompanion.insert(
            orderId: pendingOrderId,
            amountPaid: const Value(12000),
            rateOnDate: const Value(6500),
          ),
        );
    await db.into(db.orderAdvances).insert(
          OrderAdvancesCompanion.insert(
            orderId: readyOrderId,
            amountPaid: const Value(5000),
            rateOnDate: const Value(0),
          ),
        );
    await db.into(db.orderAdvances).insert(
          OrderAdvancesCompanion.insert(
            orderId: deliveredOrderId,
            amountPaid: const Value(3000),
            rateOnDate: const Value(6500),
          ),
        );

    final profile =
        await CustomerProfileRepository(db: db).fetchProfile(customerId);

    expect(profile == null, isFalse);
    expect(profile!.advanceOrders.map((order) => order.orderNo), [
      'AJ-BK-26-0003',
      'AJ-BK-26-0002',
      'AJ-BK-26-0001',
    ]);
    expect(profile.activeAdvanceCount, 2);
    expect(profile.totalAdvancePaid, 17000);
    expect(profile.advanceOrders[1].totalAdvancePaid, 5000);
    expect(profile.advanceOrders.last.estimatedTotal, 65000);
    expect(profile.advanceOrders.last.remainingBalance, 53000);

    await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'AJ-26-001',
            customerId: Value(customerId),
            sourceAdvanceOrderId: Value(readyOrderId),
          ),
        );
    final afterConversion =
        await CustomerProfileRepository(db: db).fetchProfile(customerId);
    expect(afterConversion!.activeAdvanceCount, 1);
    expect(afterConversion.totalAdvancePaid, 12000);
    expect(afterConversion.advanceOrders[1].isConvertedToSale, isTrue);
    expect(afterConversion.advanceOrders[1].isReady, isFalse);
  });

  test('cancelled bills do not inflate customer due ledger', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Reyansh Soni',
            mobile: '9304479436',
          ),
        );
    for (final (billNo, status, due) in [
      ('AJ-26-001', 'ACTIVE', 200.0),
      ('AJ-26-002', 'CANCELLED', 100.0),
    ]) {
      await db.into(db.bills).insert(
            BillsCompanion.insert(
              billNo: billNo,
              customerId: Value(customerId),
              finalAmount: Value(due),
              dueAmount: Value(due),
              paymentStatus: const Value('DUE'),
              status: Value(status),
            ),
          );
    }

    final profile =
        await CustomerProfileRepository(db: db).fetchProfile(customerId);
    expect(profile!.totalBills, 2);
    expect(profile.dueInvoiceCount, 1);
    expect(profile.totalDueAmount, 200);
    expect(profile.outstanding, 200);
  });

  test('customer with purchase or return vouchers cannot be deleted', () async {
    await db.ensureReturnReversalSchema();
    final purchaseCustomerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Purchase Customer',
            mobile: '9000000001',
          ),
        );
    await db.customStatement(
      '''
      INSERT INTO purchase_vouchers
        (voucher_no, sequence_no, source_type, customer_id, party_name, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      ['CP-001', 1, 'CUSTOMER', purchaseCustomerId, 'Purchase Customer', 1],
    );
    final repository = CustomerProfileRepository(db: db);
    final purchaseResult = await repository.deleteCustomer(purchaseCustomerId);
    expect(purchaseResult.deleted, isFalse);
    expect(purchaseResult.message, contains('customer purchase voucher'));

    final returnCustomerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Return Customer',
            mobile: '9000000002',
          ),
        );
    await db.customStatement(
      '''
      INSERT INTO return_vouchers
        (voucher_no, operation_type, source_type, source_id, source_number,
         customer_id, settlement_mode, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        'RV-001',
        'SALES_RETURN',
        'SALES_INVOICE',
        1,
        'AJ-001',
        returnCustomerId,
        'CASH_REFUND',
        1,
      ],
    );
    final returnResult = await repository.deleteCustomer(returnCustomerId);
    expect(returnResult.deleted, isFalse);
    expect(returnResult.message, contains('return voucher'));
  });

  test('customer with a delivery order cannot be deleted', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Delivery Customer',
            mobile: '9000000003',
          ),
        );
    await db.customStatement(
      '''
      INSERT INTO delivery_orders
        (delivery_no, customer_id, customer_name, customer_mobile, item_name)
      VALUES (?, ?, ?, ?, ?)
      ''',
      ['DO-001', customerId, 'Delivery Customer', '9000000003', 'Ring'],
    );

    final result =
        await CustomerProfileRepository(db: db).deleteCustomer(customerId);
    expect(result.deleted, isFalse);
    expect(result.message, contains('delivery order'));
    final customer = await (db.select(db.customers)
          ..where((row) => row.id.equals(customerId)))
        .getSingleOrNull();
    expect(customer?.id, customerId);
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
