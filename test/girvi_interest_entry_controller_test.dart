import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/girvi_controllers.dart';

void main() {
  late AppDatabase db;
  late GirviInterestEntryController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = GirviInterestEntryController(db);
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('groups tickets by customer and waits for explicit ticket selection',
      () async {
    final firstCustomer =
        await _insertCustomer(db, 'Anita Sharma', '9000000001');
    final secondCustomer =
        await _insertCustomer(db, 'Rahul Verma', '9000000002');
    await _insertLoan(db, firstCustomer, 'GRV-A-001', 'Gold chain', 50000);
    await _insertLoan(db, firstCustomer, 'GRV-A-002', 'Gold bangles', 35000);
    await _insertLoan(db, secondCustomer, 'GRV-B-001', 'Silver payal', 12000);

    await controller.load();

    expect(controller.selectedLoan, isNull);
    expect(controller.customerAccounts, hasLength(2));
    final anitaAccount = controller.customerAccounts.firstWhere(
      (account) => account.customerId == firstCustomer,
    );
    expect(anitaAccount.ticketCount, 2);
    expect(anitaAccount.outstandingPrincipal, 85000);

    controller.selectCustomerAccount(anitaAccount);

    expect(controller.selectedCustomerId, firstCustomer);
    expect(controller.selectedLoan, isNull);

    final firstTicket = anitaAccount.loans.firstWhere(
      (item) => item.loan.ticketNo == 'GRV-A-001',
    );
    await controller.selectLoan(firstTicket);

    expect(controller.selectedLoan?.loan.ticketNo, 'GRV-A-001');
    expect(controller.selectedCustomerId, firstCustomer);

    controller.selectCustomerAccount(anitaAccount);

    expect(controller.selectedLoan?.loan.ticketNo, 'GRV-A-001');

    controller.onSearchChanged('GRV-A-002');

    expect(controller.customerAccounts, hasLength(1));
    expect(controller.customerAccounts.single.ticketCount, 1);
    expect(controller.customerAccounts.single.loans.single.loan.ticketNo,
        'GRV-A-002');
  });
}

Future<int> _insertCustomer(AppDatabase db, String name, String mobile) {
  return db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: name,
          mobile: mobile,
        ),
      );
}

Future<int> _insertLoan(
  AppDatabase db,
  int customerId,
  String ticketNo,
  String itemDescription,
  double loanAmount,
) {
  return db.into(db.girviLoans).insert(
        GirviLoansCompanion.insert(
          ticketNo: ticketNo,
          customerId: customerId,
          itemDescription: itemDescription,
          grossWeight: const drift.Value(10),
          netWeight: const drift.Value(10),
          ratePerGram: const drift.Value(7000),
          totalValue: const drift.Value(70000),
          loanAmount: drift.Value(loanAmount),
          startDate: drift.Value(DateTime(2026, 6, 1)),
          maturityDate: drift.Value(DateTime(2027, 6, 1)),
        ),
      );
}
