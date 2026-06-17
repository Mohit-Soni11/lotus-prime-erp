import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';
import 'package:lotus_erp/repositories/girvi/girvi_repository.dart';

void main() {
  late AppDatabase db;
  late GirviRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GirviRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('records interest payment with receipt and paid-through date', () async {
    final loanId = await _insertLoan(db);
    final receiptNo = await repository.generateNextPaymentReceiptNo();
    final periodFrom = DateTime(2026, 1, 1);
    final periodTo = DateTime(2026, 2, 1);

    final paymentId = await repository.recordPayment(
      loanId: loanId,
      paymentType: GirviPaymentType.interest,
      paymentMode: GirviPaymentMode.cash,
      amount: 2500,
      paymentDate: periodTo,
      monthsCovered: 1,
      interestFromDate: periodFrom,
      interestToDate: periodTo,
      receiptNo: receiptNo,
      notes: 'January interest received',
    );

    final payments = await repository.getPaymentModelsForLoan(loanId);
    final loan = await repository.getLoanById(loanId);

    expect(paymentId, isPositive);
    expect(receiptNo, 'GIP-00001');
    expect(payments, hasLength(1));
    expect(payments.single.receiptNo, 'GIP-00001');
    expect(payments.single.amount, 2500);
    expect(payments.single.monthsCovered, 1);
    expect(payments.single.balanceAfter, 50000);
    expect(loan!.loanAmount, 50000);
    expect(loan.lastInterestPaidDate, periodTo);
  });

  test('records partial principal payment and updates outstanding principal',
      () async {
    final loanId = await _insertLoan(db);

    await repository.recordPayment(
      loanId: loanId,
      paymentType: GirviPaymentType.partialPrincipal,
      paymentMode: GirviPaymentMode.upi,
      amount: 12000,
      paymentDate: DateTime(2026, 2, 10),
      receiptNo: 'GIP-00099',
    );

    final loan = await repository.getLoanById(loanId);
    final payments = await repository.getPaymentModelsForLoan(loanId);

    expect(loan!.loanAmount, 38000);
    expect(
        payments.single.paymentType, GirviPaymentType.partialPrincipal.dbValue);
    expect(payments.single.balanceAfter, 38000);
    expect(payments.single.paymentMode, GirviPaymentMode.upi.dbValue);
  });

  test('interest payment advances paid-through date without reducing principal',
      () async {
    final loanId = await _insertLoan(
      db,
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
    );

    await repository.recordPayment(
      loanId: loanId,
      paymentType: GirviPaymentType.interest,
      paymentMode: GirviPaymentMode.cash,
      amount: 4000,
      paymentDate: DateTime(2026, 4, 1),
      receiptNo: 'GIP-ADV-001',
    );

    final loan = await repository.getLoanById(loanId);
    final payment = (await repository.getPaymentModelsForLoan(loanId)).single;

    expect(loan!.loanAmount, 5000);
    expect(loan.lastInterestPaidDate, DateTime(2027, 5, 1));
    expect(payment.amount, 4000);
    expect(payment.monthsCovered, 16);
    expect(payment.interestFromDate, DateTime(2026, 1, 1));
    expect(payment.interestToDate, DateTime(2027, 5, 1));
    expect(payment.balanceAfter, 5000);

    final advanceSnapshot = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2026, 4, 1),
      lastInterestPaidDate: loan.lastInterestPaidDate,
    );
    expect(advanceSnapshot.accruedInterest, 0);
    expect(advanceSnapshot.advanceInterestMonths, 13);
    expect(advanceSnapshot.advanceInterestAmount, 3250);
  });

  test('girvi interest charges started months and compounds annually', () {
    expect(
      GirviLoanModel.chargeableMonthsBetween(
        DateTime(2025, 6, 17),
        DateTime(2026, 6, 17, 14, 8),
      ),
      12,
    );
    expect(
      GirviLoanModel.chargeableMonthsBetween(
        DateTime(2025, 6, 17),
        DateTime(2026, 6, 18),
      ),
      13,
    );

    final oneStartedMonth = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2026, 1, 2),
    );
    final annualCycle = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2027, 1, 1),
    );
    final monthAfterAnnualCycle = _loanModel(
      loanAmount: 5000,
      interestRate: 5,
      startDate: DateTime(2026, 1, 1),
      releaseDate: DateTime(2027, 2, 1),
    );
    final seventeenMonthLoan = _loanModel(
      loanAmount: 50000,
      interestRate: 5,
      startDate: DateTime(2025, 2, 9),
      releaseDate: DateTime(2026, 6, 17),
    );
    final seventeenMonthBreakdown = seventeenMonthLoan.accruedInterestBreakdown;
    final seventeenMonthElapsed =
        seventeenMonthLoan.unpaidInterestElapsedPeriod;

    expect(oneStartedMonth.accruedInterest, 250);
    expect(annualCycle.accruedInterest, 3000);
    expect(monthAfterAnnualCycle.accruedInterest, 3400);
    expect(seventeenMonthBreakdown, hasLength(2));
    expect(seventeenMonthBreakdown[0].months, 12);
    expect(seventeenMonthBreakdown[0].principalBase, 50000);
    expect(seventeenMonthBreakdown[0].interestAmount, 30000);
    expect(seventeenMonthBreakdown[0].capitalizedAfterLine, isTrue);
    expect(seventeenMonthBreakdown[1].months, 5);
    expect(seventeenMonthBreakdown[1].principalBase, 80000);
    expect(seventeenMonthBreakdown[1].interestAmount, 20000);
    expect(seventeenMonthElapsed.years, 1);
    expect(seventeenMonthElapsed.months, 4);
    expect(seventeenMonthElapsed.days, 8);
  });
}

Future<int> _insertLoan(
  AppDatabase db, {
  double loanAmount = 50000,
  double interestRate = 5,
  DateTime? startDate,
}) async {
  final customerId = await db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: 'Interest Entry Customer',
          mobile: '9999999999',
        ),
      );

  return db.into(db.girviLoans).insert(
        GirviLoansCompanion.insert(
          ticketNo: 'GRV-INT-0001',
          customerId: customerId,
          itemDescription: 'Gold chain',
          grossWeight: const drift.Value(12),
          netWeight: const drift.Value(12),
          ratePerGram: const drift.Value(7000),
          totalValue: const drift.Value(84000),
          loanAmount: drift.Value(loanAmount),
          interestRate: drift.Value(interestRate),
          startDate: drift.Value(startDate ?? DateTime(2026, 1, 1)),
        ),
      );
}

GirviLoanModel _loanModel({
  required double loanAmount,
  required double interestRate,
  required DateTime startDate,
  DateTime? releaseDate,
  DateTime? lastInterestPaidDate,
}) {
  return GirviLoanModel(
    id: 1,
    ticketNo: 'GRV-TEST',
    customerId: 1,
    itemDescription: 'Gold item',
    itemCount: 1,
    metalType: 'Gold',
    metalPurity: '22K',
    grossWeight: 1,
    stoneWeight: 0,
    netWeight: 1,
    ratePerGram: 1,
    totalValue: 1,
    ltvPercent: 1,
    loanAmount: loanAmount,
    interestRate: interestRate,
    durationMonths: 12,
    disbursementMode: 'Cash',
    startDate: startDate,
    releaseDate: releaseDate,
    lastInterestPaidDate: lastInterestPaidDate,
    createdAt: startDate,
  );
}
