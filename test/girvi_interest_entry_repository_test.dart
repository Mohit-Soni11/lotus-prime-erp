import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
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
}

Future<int> _insertLoan(AppDatabase db) async {
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
          loanAmount: const drift.Value(50000),
          interestRate: const drift.Value(5),
          startDate: drift.Value(DateTime(2026, 1, 1)),
        ),
      );
}
