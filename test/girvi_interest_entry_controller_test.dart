import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/girvi_controllers.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';

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

    controller.showBillSelectionForSelectedCustomer();

    expect(controller.selectedCustomerId, firstCustomer);
    expect(controller.selectedLoan, isNull);

    await controller.selectLoan(firstTicket);

    controller.onSearchChanged('GRV-A-002');

    expect(controller.customerAccounts, hasLength(1));
    expect(controller.customerAccounts.single.ticketCount, 1);
    expect(controller.customerAccounts.single.loans.single.loan.ticketNo,
        'GRV-A-002');
  });

  test('release discount auto-fills the net settlement interest first',
      () async {
    final customerId =
        await _insertCustomer(db, 'Discount Customer', '9000000010');
    await _insertLoan(
      db,
      customerId,
      'GRV-DISC-001',
      'Gold ring',
      50000,
    );

    await controller.load();
    final account = controller.customerAccounts.single;
    await controller.selectLoan(account.loans.single);
    controller.setPaymentType(GirviPaymentType.fullRelease);

    final grossDue = controller.releaseTotalDueForSelected;
    final interestDue = controller.netInterestDueForSelected;
    final discount = interestDue > 1000 ? 1000.0 : interestDue;

    controller.onReleaseDiscountChanged(discount.toStringAsFixed(0));

    expect(controller.releaseDiscount, discount);
    expect(
      controller.releasePrincipalReceived,
      controller.releasePrincipalDueForSelected,
    );
    expect(
      controller.releaseInterestReceived,
      interestDue - discount,
    );
    expect(
      controller.releaseSettlementValue,
      closeTo(grossDue, 0.01),
    );
  });

  test('release discount cannot reduce locked principal', () async {
    final customerId =
        await _insertCustomer(db, 'Locked Principal Customer', '9000000011');
    await _insertLoan(
      db,
      customerId,
      'GRV-LOCK-001',
      'Gold bracelet',
      50000,
    );

    await controller.load();
    final account = controller.customerAccounts.single;
    await controller.selectLoan(account.loans.single);
    controller.setPaymentType(GirviPaymentType.fullRelease);

    final principalDue = controller.releasePrincipalDueForSelected;
    final interestDue = controller.netInterestDueForSelected;

    controller.onReleaseDiscountChanged((interestDue + 1).toStringAsFixed(0));

    expect(controller.releasePrincipalReceived, principalDue);
    expect(await controller.recordPayment(), isFalse);
    expect(
      controller.errorMessage,
      'Interest discount cannot exceed interest due.',
    );
  });

  test('delivers ready ticket even when expected pickup date is overdue',
      () async {
    final customerId =
        await _insertCustomer(db, 'Delayed Pickup Customer', '9000000012');
    final loanId = await _insertLoan(
      db,
      customerId,
      'GRV-PICK-001',
      'Gold chain',
      25000,
      status: GirviStatus.readyForDelivery,
      releaseDate: DateTime(2026, 9, 22),
      expectedDeliveryDate: DateTime(2026, 9, 22),
      releasePrincipal: 25000,
      releaseTotalAmount: 25000,
    );

    await controller.load();
    final account = controller.customerAccounts.single;
    await controller.selectLoan(account.loans.single);
    controller.setPaymentType(GirviPaymentType.fullRelease);

    expect(await controller.recordPayment(), isTrue);

    final loan = await db.managers.girviLoans
        .filter((row) => row.id(loanId))
        .getSingle();

    expect(controller.errorMessage, isNull);
    expect(loan.status, GirviStatus.released.dbValue);
    expect(loan.deliveredAt, isNotNull);
    expect(loan.expectedDeliveryDate, loan.deliveredAt);
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
  double loanAmount, {
  GirviStatus status = GirviStatus.active,
  DateTime? releaseDate,
  DateTime? expectedDeliveryDate,
  double? releasePrincipal,
  double? releaseInterest,
  double? releaseDiscount,
  double? releaseTotalAmount,
}) {
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
          status: drift.Value(status.dbValue),
          releaseDate: drift.Value(releaseDate),
          expectedDeliveryDate: drift.Value(expectedDeliveryDate),
          releasePrincipal: drift.Value(releasePrincipal),
          releaseInterest: drift.Value(releaseInterest),
          releaseDiscount: drift.Value(releaseDiscount),
          releaseTotalAmount: drift.Value(releaseTotalAmount),
        ),
      );
}
