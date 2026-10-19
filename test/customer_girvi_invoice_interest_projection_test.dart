import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_interest_calculator.dart';
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
    } finally {
      await db.close();
    }
  });
}
