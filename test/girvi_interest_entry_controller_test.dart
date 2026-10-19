import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/girvi_controllers.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/repositories/girvi/girvi_repository.dart';

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

  test(
      'final release recalculates payable interest when collection date changes',
      () async {
    final customerId =
        await _insertCustomer(db, 'Date Change Customer', '9000000015');
    await _insertLoan(
      db,
      customerId,
      'GRV-DATE-001',
      'Gold ring',
      50000,
      startDate: DateTime(2026, 1, 1),
      interestRate: 1,
    );

    await controller.load();
    await controller
        .selectLoan(controller.customerAccounts.single.loans.single);
    controller.setPaymentDate(DateTime(2026, 1, 20));
    controller.setPaymentType(GirviPaymentType.fullRelease);
    controller.onReleaseDiscountChanged('100');
    final earlierInterest = controller.releaseInterestReceived;

    controller.setPaymentDate(DateTime(2026, 2, 2));

    expect(controller.releaseInterestReceived, greaterThan(earlierInterest));
    expect(controller.releaseInterestReceived,
        controller.netInterestDueForSelected - 100);
    expect(controller.releaseSettlementValue,
        controller.releaseTotalDueForSelected);
  });

  test('interest entry and pledge ledger agree after year-one payment',
      () async {
    final customerId =
        await _insertCustomer(db, 'Compound Customer', '9000000013');
    final loanId = await _insertLoan(
      db,
      customerId,
      'GRV-COMP-001',
      'Gold ring',
      100000,
      startDate: DateTime(2025, 1, 1),
      interestRate: 1,
    );
    final repository = GirviRepository(db);
    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 12000,
      paymentDate: DateTime(2026, 1, 1),
    );

    await controller.load();
    await controller
        .selectLoan(controller.customerAccounts.single.loans.single);
    controller.setPaymentDate(DateTime(2026, 2, 1));
    controller.onAmountChanged('1000');

    final ledgerQuote = (await repository.getLoansWithCustomer())
        .single
        .interestQuoteAt(DateTime(2026, 2, 1));
    expect(ledgerQuote.interestType, 'Compound');
    expect(controller.amount, 1000);
    expect(controller.selectedInterestQuote!.lastChargedMonthlyInterest,
        ledgerQuote.lastChargedMonthlyInterest);
    expect(
        controller.grossInterestAccruedForSelected, ledgerQuote.grossInterest);
    expect(
        controller.netInterestDueForSelected, ledgerQuote.interestOutstanding);
    expect(ledgerQuote.interestOutstanding, 1000);
  });

  test('partial interest collection stays amount based for GRV-0019 timeline',
      () async {
    final customerId =
        await _insertCustomer(db, 'Partial Payment Customer', '9000000014');
    final loanId = await _insertLoan(
      db,
      customerId,
      'GRV-0019',
      'Gold ring',
      3000,
      startDate: DateTime(2025, 5, 5),
      interestRate: 5,
    );
    final repository = GirviRepository(db);
    final collectionDate = DateTime(2026, 10, 19);
    await repository.recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 2000,
      paymentDate: collectionDate,
    );

    await controller.load();
    await controller
        .selectLoan(controller.customerAccounts.single.loans.single);
    controller.setPaymentDate(collectionDate);

    expect(controller.grossInterestAccruedForSelected, 3240);
    expect(controller.interestCollectedForSelected, 2000);
    expect(controller.netInterestDueForSelected, 1240);
    expect(controller.amount, 0);
    final firstPayment = controller.payments.single;
    final firstBalance = controller.ledgerBalances[firstPayment.id]!;
    expect(firstBalance.principalRemaining, 3000);
    expect(firstBalance.interestRemaining, 1240);
    expect(firstBalance.totalRemaining, 4240);

    controller.onAmountChanged('500');
    expect(controller.amount, 500);
    expect(await controller.recordPayment(), isTrue);
    controller.setPaymentDate(collectionDate);

    expect(controller.interestCollectedForSelected, 2500);
    expect(controller.netInterestDueForSelected, 740);
    expect(controller.amount, 0);
    expect(controller.ledgerBalances[firstPayment.id]!.interestRemaining, 1240);
    final secondPayment = controller.payments
        .firstWhere((payment) => payment.id != firstPayment.id);
    expect(
        controller.ledgerBalances[secondPayment.id]!.principalRemaining, 3000);
    expect(controller.ledgerBalances[secondPayment.id]!.interestRemaining, 740);
    expect(controller.ledgerBalances[secondPayment.id]!.totalRemaining, 3740);
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

  test('rejects invalid collection dates and records a rapid submit once',
      () async {
    final customerId =
        await _insertCustomer(db, 'Collection Customer', '9000000013');
    await _insertLoan(
      db,
      customerId,
      'GRV-DATE-001',
      'Gold chain',
      3000,
      startDate: DateTime(2026, 6, 1),
      interestRate: 5,
    );
    await controller.load();
    await controller
        .selectLoan(controller.customerAccounts.single.loans.single);
    controller.onAmountChanged('500');

    controller.setPaymentDate(DateTime(2026, 5, 31));
    expect(await controller.recordPayment(), isFalse);
    expect(controller.errorMessage, contains('before the pledge date'));

    controller.setPaymentDate(DateTime.now().add(const Duration(days: 2)));
    expect(await controller.recordPayment(), isFalse);
    expect(controller.errorMessage, contains('in the future'));

    controller.setPaymentDate(DateTime.now());
    final results = await Future.wait([
      controller.recordPayment(),
      controller.recordPayment(),
    ]);
    expect(results.where((result) => result), hasLength(1));
    expect(controller.payments, hasLength(1));
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
  DateTime? startDate,
  double interestRate = 0,
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
          loanAmount: drift.Value(loanAmount),
          interestRate: drift.Value(interestRate),
          startDate: drift.Value(startDate ?? DateTime(2026, 6, 1)),
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
