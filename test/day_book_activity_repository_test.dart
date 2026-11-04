import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_activity_event.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/repositories/reports/day_book_activity_repository.dart';

void main() {
  test('release and melted collateral use their own dated source events',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Customer', mobile: '9000000777'),
        );
    final prior = DateTime(2026, 11, 1);
    final today = DateTime(2026, 11, 4, 12);
    final releaseId = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-RELEASE',
            customerId: customerId,
            itemDescription: 'Ring',
            startDate: drift.Value(prior),
            releaseDate: drift.Value(today),
            releaseTotalAmount: const drift.Value(1100),
            status: const drift.Value('RELEASED'),
          ),
        );
    final meltId = await db.into(db.girviLoans).insert(
          GirviLoansCompanion.insert(
            ticketNo: 'GRV-MELT',
            customerId: customerId,
            itemDescription: 'Chain',
            startDate: drift.Value(prior),
          ),
        );
    await db.into(db.girviPayments).insert(GirviPaymentsCompanion.insert(
          girviId: releaseId,
          paymentType: 'FULL_RELEASE',
          amount: const drift.Value(1100),
          interestComponent: const drift.Value(100),
          paymentDate: drift.Value(today),
        ));
    for (final serial in [1, 2]) {
      await db.into(db.girviLoanItems).insert(
            GirviLoanItemsCompanion.insert(
              girviId: meltId,
              serialNo: serial,
              itemName: 'Item $serial',
              metalType: 'Gold',
              purity: '22K',
              purityFactor: const drift.Value(0.916),
              recoveryDispositionStatus: const drift.Value('MELTED'),
              recoveryDisposedAt: drift.Value(today),
            ),
          );
    }
    final events = await DayBookActivityRepository(db).fetch(today);
    expect(events, hasLength(3));
    expect(
        events
            .singleWhere((event) =>
                event.sourceId == releaseId &&
                event.kind == DayBookActivityKind.girviRelease)
            .amount,
        1100);
    expect(
        events
            .singleWhere((event) =>
                event.sourceId == releaseId &&
                event.kind == DayBookActivityKind.girviInterest)
            .amount,
        100);
    expect(events.singleWhere((event) => event.sourceId == meltId).kind,
        DayBookActivityKind.girviMelted);
    expect(events.singleWhere((event) => event.sourceId == meltId).amount, 0);
    expect(await DayBookActivityRepository(db).fetch(prior), isEmpty);
  });

  test('only bill linked due receipts appear, split modes combine', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 11, 4);
    final customerId = await db.into(db.customers).insert(
          CustomersCompanion.insert(name: 'Due Customer', mobile: '9000000666'),
        );
    final billId = await db.into(db.bills).insert(BillsCompanion.insert(
          billNo: 'INV-OLD',
          customerId: drift.Value(customerId),
          billDate: drift.Value(date.subtract(const Duration(days: 3))),
        ));
    DayBookMoneyEntry receipt(String id, double amount, String type) =>
        DayBookMoneyEntry(
          date: date,
          amount: amount,
          incoming: true,
          isCash: id == 'cash',
          category: 'DUE_COLLECTION',
          paymentMode: id == 'cash' ? 'CASH' : 'UPI',
          transactionId: id,
          referenceType: type,
          referenceId: type == 'BILL' ? 'INV-OLD#PAY' : 'GIRVI-4',
        );
    final flow = DayBookMoneyFlow(openingCash: 0, openingBank: 0, entries: [
      receipt('cash', 300, 'BILL'),
      receipt('bank', 200, 'BILL'),
      receipt('girvi', 900, 'GIRVI'),
    ]);
    final events =
        await DayBookActivityRepository(db).fetch(date, moneyFlow: flow);
    expect(events, hasLength(1));
    expect(events.single.kind, DayBookActivityKind.dueCollection);
    expect(events.single.amount, 500);
    expect(events.single.sourceId, billId);
  });
}
