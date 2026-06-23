import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/girvi_controllers.dart';
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

  test('legacy release controller blocks delivery before settlement', () async {
    final loanId = await _insertLoan(db, GirviStatus.active);
    final loan = (await repository.getLoansWithCustomer(loanId: loanId)).single;
    final controller = GirviReleaseController(
      db: db,
      loan: loan.loan,
      customerName: loan.customerName,
    );
    addTearDown(controller.dispose);

    final ok = await controller.processRelease(releasedBy: 'Test Staff');
    final stored = await repository.getLoanById(loanId);

    expect(ok, isFalse);
    expect(
      controller.errorMessage,
      'Complete the settlement in Interest Entry before delivery.',
    );
    expect(stored!.status, GirviStatus.active.dbValue);
    expect(stored.deliveredAt, isNull);
  });

  test('legacy release controller only marks ready account delivered',
      () async {
    final loanId = await _insertLoan(db, GirviStatus.readyForDelivery);
    final loan = (await repository.getLoansWithCustomer(loanId: loanId)).single;
    final controller = GirviReleaseController(
      db: db,
      loan: loan.loan,
      customerName: loan.customerName,
    );
    addTearDown(controller.dispose);

    final ok = await controller.processRelease(releasedBy: 'Test Staff');
    final stored = await repository.getLoanById(loanId);

    expect(ok, isTrue);
    expect(
        controller.successMessage, 'Girvi GRV-REL-001 delivered successfully!');
    expect(stored!.status, GirviStatus.released.dbValue);
    expect(stored.deliveredAt, isNotNull);
    expect(stored.releasedBy, 'Test Staff');
  });
}

Future<int> _insertLoan(AppDatabase db, GirviStatus status) async {
  final customerId = await db.into(db.customers).insert(
        CustomersCompanion.insert(
          name: 'Release Customer',
          mobile: '9000000001',
        ),
      );

  return db.into(db.girviLoans).insert(
        GirviLoansCompanion.insert(
          ticketNo: 'GRV-REL-001',
          customerId: customerId,
          itemDescription: 'Gold ring',
          grossWeight: const drift.Value(4),
          netWeight: const drift.Value(4),
          ratePerGram: const drift.Value(7800),
          totalValue: const drift.Value(31200),
          loanAmount: const drift.Value(12000),
          interestRate: const drift.Value(5),
          startDate: drift.Value(DateTime(2026, 3, 10)),
          maturityDate: drift.Value(DateTime(2026, 9, 10)),
          status: drift.Value(status.dbValue),
          releaseDate: status == GirviStatus.readyForDelivery
              ? drift.Value(DateTime(2026, 6, 20))
              : const drift.Value.absent(),
          expectedDeliveryDate: status == GirviStatus.readyForDelivery
              ? drift.Value(DateTime(2026, 6, 22))
              : const drift.Value.absent(),
        ),
      );
}
