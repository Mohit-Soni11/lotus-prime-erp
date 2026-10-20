import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/girvi_account_detail_controller.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/repositories/girvi/girvi_repository.dart';

void main() {
  test('account refresh loads new collection and disbursement breakdown',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = GirviAccountDetailController(db);
    addTearDown(controller.dispose);
    addTearDown(db.close);

    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: 'Account Customer',
            mobile: '9000000041',
          ),
        );
    final startDate = DateTime.now().subtract(const Duration(days: 10));
    final loanId = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-ACCOUNT-001',
            customerId: customerId,
            itemDescription: 'Gold ring',
            loanAmount: const drift.Value(5000),
            interestRate: const drift.Value(2),
            startDate: drift.Value(startDate),
          ),
        );
    for (final entry in [(1, 'Cash', 2000.0), (2, 'UPI', 3000.0)]) {
      await db.into(db.girviDisbursements).insert(
            GirviDisbursementsCompanion.insert(
              girviId: loanId,
              sequenceNo: entry.$1,
              mode: entry.$2,
              displayLabel: entry.$2,
              amount: entry.$3,
            ),
          );
    }

    await controller.load(loanId);
    expect(controller.errorMessage, isNull);
    expect(controller.details!.disbursements.map((entry) => entry.amount),
        [2000, 3000]);
    expect(controller.payments, isEmpty);

    await GirviRepository(db).recordInterestLedgerPayment(
      loanId: loanId,
      paymentMode: GirviPaymentMode.cash,
      amount: 100,
      paymentDate: DateTime.now(),
    );

    final loadingStates = <bool>[];
    controller.addListener(() => loadingStates.add(controller.isLoading));
    await controller.load(loanId, showLoading: false);

    expect(loadingStates, everyElement(isFalse));
    expect(controller.errorMessage, isNull);
    expect(controller.payments, hasLength(1));
    expect(controller.payments.single.amount, 100);
    expect(controller.account!.interestPaidTotal, 100);
    expect(controller.details!.disbursements, hasLength(2));
  });
}
