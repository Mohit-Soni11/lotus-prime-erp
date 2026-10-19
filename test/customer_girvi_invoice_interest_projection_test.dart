import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_interest_calculator.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_draft.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';
import 'package:lotus_erp/repositories/girvi/girvi_repository.dart';

void main() {
  test('customer interest receipt uses the same year-two quote as ledger',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Receipt Customer',
              mobile: '9000000014',
            ),
          );
      final start = DateTime.now().subtract(const Duration(days: 400));
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-RCPT-001',
              customerId: customerId,
              itemDescription: 'Gold ring',
              grossWeight: const drift.Value(10),
              netWeight: const drift.Value(10),
              loanAmount: const drift.Value(100000),
              interestRate: const drift.Value(1),
              startDate: drift.Value(start),
            ),
          );
      await GirviRepository(db).recordInterestLedgerPayment(
        loanId: loanId,
        paymentMode: GirviPaymentMode.cash,
        amount: 12000,
        paymentDate: DateTime.now(),
      );

      final draft = await CustomerProfileRepository(db: db)
          .fetchGirviInvoiceDraft(customerId: customerId, loanId: loanId);
      final quote = GirviInterestCalculator.quoteAt(
        principal: 100000,
        monthlyRatePercent: 1,
        startDate: start,
        asOf: DateTime.now(),
        adjustments: [
          GirviInterestAdjustment(date: DateTime.now(), paid: 12000),
        ],
      );

      expect(draft, isNotNull);
      expect(draft!.monthlyInterest, quote.currentMonthlyInterest);
      expect(draft.totalInterest, quote.grossInterest);
      expect(draft.interestOutstanding, quote.interestOutstanding);
      expect(draft.interestAdjustments, hasLength(1));
      expect(draft.interestAdjustments.single.paid, 12000);
      expect(draft.interestPrincipal, 100000);
      expect(draft.interestAsOfDate, isNotNull);
      expect(draft.interestQuote.currentMonthlyInterestType,
          GirviInterestCalculationType.simple);

      final printable = draft.copyWith(mode: GirviReceiptMode.interest);
      expect(printable.interestPrincipal, draft.interestPrincipal);
      expect(printable.interestAsOfDate, draft.interestAsOfDate);
      expect(printable.interestAdjustments, draft.interestAdjustments);
      expect(printable.interestQuote.interestOutstanding,
          draft.interestQuote.interestOutstanding);

      final original = draft.copyWith(
        mode: GirviReceiptMode.pledge,
        clearLifecycleFields: true,
      );
      expect(original.interestAdjustments, isEmpty);
      expect(original.interestAsOfDate, draft.createdAt);
    } finally {
      await db.close();
    }
  });

  test(
      'partial interest without a full paid month still opens an interest receipt',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Partial Receipt Customer',
              mobile: '9000000015',
            ),
          );
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-PARTIAL-001',
              customerId: customerId,
              itemDescription: 'Gold ring',
              grossWeight: const drift.Value(8),
              netWeight: const drift.Value(8),
              loanAmount: const drift.Value(3000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(
                  DateTime.now().subtract(const Duration(days: 10))),
            ),
          );
      await GirviRepository(db).recordInterestLedgerPayment(
        loanId: loanId,
        paymentMode: GirviPaymentMode.cash,
        amount: 50,
        paymentDate: DateTime.now(),
      );

      final draft = await CustomerProfileRepository(db: db)
          .fetchGirviInvoiceDraft(customerId: customerId, loanId: loanId);

      expect(draft, isNotNull);
      expect(draft!.mode, GirviReceiptMode.interest);
      expect(draft.interestQuote.interestOutstanding, 100);
      expect(draft.interestQuote.currentMonthlyInterestType,
          GirviInterestCalculationType.simple);
    } finally {
      await db.close();
    }
  });

  test(
      'partial settlement retains its outstanding balances and is not a release',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Settlement Customer',
              mobile: '9000000016',
            ),
          );
      final today = DateTime.now();
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-SETTLEMENT-001',
              customerId: customerId,
              itemDescription: 'Gold ring',
              loanAmount: const drift.Value(3000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(today.subtract(const Duration(days: 40))),
              status: drift.Value(GirviStatus.partialRelease.dbValue),
              releaseTotalAmount: const drift.Value(600),
            ),
          );
      await db.into(db.girviPayments).insert(
            GirviPaymentsCompanion.insert(
              girviId: loanId,
              paymentType: GirviPaymentType.fullRelease.dbValue,
              paymentDate: drift.Value(today),
              amount: const drift.Value(600),
              paymentMode: drift.Value(GirviPaymentMode.cash.dbValue),
              principalComponent: const drift.Value(500),
              interestComponent: const drift.Value(100),
            ),
          );

      final draft = await CustomerProfileRepository(db: db)
          .fetchGirviInvoiceDraft(customerId: customerId, loanId: loanId);

      expect(draft, isNotNull);
      expect(draft!.mode, GirviReceiptMode.interest);
      expect(draft.isReleaseReceipt, isFalse);
      expect(draft.principalOutstanding, 2500);
      expect(draft.interestOutstanding, greaterThan(0));
      expect(draft.totalOutstanding,
          closeTo(2500 + draft.interestOutstanding!, 0.01));
      expect(draft.ledgerEntries.single.principalAmount, 500);
      expect(draft.ledgerEntries.single.interestAmount, 100);
    } finally {
      await db.close();
    }
  });
}
