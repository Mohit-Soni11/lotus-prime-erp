import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/customer/customer_enums/customer_list_enums.dart';
import 'package:lotus_erp/repositories/customer/customer_list_repository.dart';

void main() {
  late AppDatabase db;
  late CustomerListRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CustomerListRepository(db: db);
  });

  tearDown(() => db.close());

  test('aggregates bills, advance orders and Girvi without double counting',
      () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Asha', mobile: '9000000001'),
        );
    final otherId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Zara', mobile: '9000000002'),
        );

    await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'SALE-1',
            customerId: Value(customerId),
            billDate: Value(DateTime(2026, 1, 2)),
            finalAmount: const Value(1000),
            paidAmount: const Value(400),
            dueAmount: const Value(600),
            paymentStatus: const Value('DUE'),
          ),
        );
    await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'SALE-VOID',
            customerId: Value(customerId),
            billDate: Value(DateTime(2026, 1, 3)),
            finalAmount: const Value(500),
            dueAmount: const Value(500),
            status: const Value('CANCELLED'),
          ),
        );
    await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'OTHER',
            customerId: Value(otherId),
            billDate: Value(DateTime(2026, 1, 2)),
            finalAmount: const Value(700),
          ),
        );
    await db.into(db.salesOrders).insert(
          SalesOrdersCompanion.insert(
            orderNo: 'ADV-1',
            customerId: customerId,
            itemName: 'Ring',
            status: const Value('PENDING'),
          ),
        );
    await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-1',
            customerId: customerId,
            itemDescription: 'Chain',
            loanAmount: const Value(2000),
            status: const Value('OVERDUE'),
          ),
        );

    final results =
        await repository.getAllCustomers(sort: CustomerSort.nameAsc);
    final asha = results.first;

    expect(results.map((customer) => customer.name), ['Asha', 'Zara']);
    expect(asha.billCount, 1);
    expect(asha.invoiceValue, 1000);
    expect(asha.dueAmount, 600);
    expect(asha.activeAdvanceCount, 1);
    expect(asha.activeGirviCount, 1);
    expect(results.last.billCount, 1);
    expect(results.last.invoiceValue, 700);
    expect(results.last.dueAmount, 0);
  });

  test('directory due total follows the customer bill due policy', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Due Customer', mobile: '9000000013'),
        );
    Future<void> addBill(
      String number, {
      required double finalAmount,
      required double paidAmount,
      required double dueAmount,
      required String paymentStatus,
    }) async {
      await db.into(db.bills).insert(
            BillsCompanion.insert(
              billNo: number,
              customerId: Value(customerId),
              finalAmount: Value(finalAmount),
              paidAmount: Value(paidAmount),
              dueAmount: Value(dueAmount),
              paymentStatus: Value(paymentStatus),
            ),
          );
    }

    await addBill(
      'PAID-WITH-STALE-DUE',
      finalAmount: 100,
      paidAmount: 100,
      dueAmount: 50,
      paymentStatus: 'PAID',
    );
    await addBill(
      'PARTIAL',
      finalAmount: 200,
      paidAmount: 75,
      dueAmount: 125,
      paymentStatus: 'PARTIAL',
    );
    await addBill(
      'LEGACY-FALLBACK',
      finalAmount: 300,
      paidAmount: 100,
      dueAmount: 0,
      paymentStatus: 'UNKNOWN',
    );

    final customer = (await repository.getAllCustomers()).single;
    expect(customer.billCount, 3);
    expect(customer.dueAmount, 325);
  });

  test('latest cancelled invoice is an activity but not a sale', () async {
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Cancelled Customer',
            mobile: '9000000014',
            createdAt: Value(DateTime(2025, 1, 1)),
          ),
        );
    await db.into(db.bills).insert(
          BillsCompanion.insert(
            billNo: 'VOID-1',
            customerId: Value(customerId),
            billDate: Value(DateTime(2026, 1, 3)),
            finalAmount: const Value(1000),
            dueAmount: const Value(1000),
            status: const Value('CANCELLED'),
            paymentStatus: const Value('DUE'),
          ),
        );

    final customer = (await repository.getAllCustomers()).single;
    expect(customer.billCount, 0);
    expect(customer.invoiceValue, 0);
    expect(customer.dueAmount, 0);
    expect(customer.lastActivityAt.year, 2026);
    expect(customer.lastActivityLabel, 'Invoice VOID-1');
    expect(customer.lastActivityDetail, 'Invoice cancelled');
  });
}
