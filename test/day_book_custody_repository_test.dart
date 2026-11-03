import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/reports/day_book_custody_repository.dart';

void main() {
  test('customer custody carries opening, receipt and actual handover',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(
              name: 'Custody Customer', mobile: '9000000456'),
        );
    final receivedAt = DateTime(2026, 6, 25, 10);
    final deliveredAt = DateTime(2026, 6, 27, 14);
    final loanId = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-1',
            customerId: customerId,
            itemDescription: 'Gold and Silver items',
            startDate: drift.Value(receivedAt),
            releaseDate: drift.Value(DateTime(2026, 6, 26)),
            deliveredAt: drift.Value(deliveredAt),
            status: const drift.Value('RELEASED'),
          ),
        );
    await db.into(db.girviLoanItems).insert(
          GirviLoanItemsCompanion.insert(
            girviId: loanId,
            serialNo: 1,
            itemName: 'Gold Ring',
            metalType: 'Gold',
            purity: '22K',
            pieces: const drift.Value(1),
            grossWeight: const drift.Value(12),
            netWeight: const drift.Value(10),
            purityFactor: const drift.Value(0.916),
          ),
        );
    await db.into(db.girviLoanItems).insert(
          GirviLoanItemsCompanion.insert(
            girviId: loanId,
            serialNo: 2,
            itemName: 'Silver Chain',
            metalType: 'Silver',
            purity: '925',
            pieces: const drift.Value(1),
            grossWeight: const drift.Value(21),
            netWeight: const drift.Value(20),
            purityFactor: const drift.Value(0.925),
          ),
        );

    final repository = DayBookCustodyRepository(db);
    final first = await repository.fetch(receivedAt);
    expect(first.received, hasLength(2));
    expect(first.opening, isEmpty);
    expect(first.closing, hasLength(2));
    expect(first.received.first.fineWeight, closeTo(9.16, 0.0001));

    final settled = await repository.fetch(DateTime(2026, 6, 26));
    expect(settled.opening, hasLength(2));
    expect(settled.released, isEmpty);
    expect(settled.closing, hasLength(2));

    final handover = await repository.fetch(deliveredAt);
    expect(handover.opening, hasLength(2));
    expect(handover.released, hasLength(2));
    expect(handover.closing, isEmpty);
  });
}
