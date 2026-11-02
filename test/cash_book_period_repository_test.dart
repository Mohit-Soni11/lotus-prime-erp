import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/finance/cash_book_period_repository.dart';

void main() {
  test('monthly and yearly history includes only active cash transactions',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.shopProfiles).insert(const ShopProfilesCompanion(
          openingCashBalance: drift.Value(100),
        ));

    Future<void> insert(String id, DateTime date, String type, double amount,
        {String mode = 'CASH', bool voided = false}) async {
      await db
          .into(db.cashTransactions)
          .insert(CashTransactionsCompanion.insert(
            txnId: id,
            txnDate: date,
            type: type,
            category: 'OTHER_INCOME',
            amount: drift.Value(amount),
            paymentMode: drift.Value(mode),
            isVoided: drift.Value(voided),
          ));
    }

    await insert('2021-IN', DateTime(2021, 4, 5, 12), 'INCOME', 50);
    await insert('2025-OUT', DateTime(2025, 8, 5, 12), 'EXPENSE', 20);
    await insert('JAN-IN', DateTime(2026, 1, 5, 12), 'INCOME', 60);
    await insert('JAN-OUT', DateTime(2026, 1, 8, 12), 'EXPENSE', 10);
    await insert('JAN-END', DateTime(2026, 1, 31, 23, 55), 'INCOME', 7);
    await insert('FEB-IN', DateTime(2026, 2, 5, 12), 'INCOME', 40);
    await insert('FEB-START', DateTime(2026, 2, 1, 0, 5), 'INCOME', 3);
    await insert('SEP-OUT', DateTime(2026, 9, 5, 12), 'EXPENSE', 25);
    await insert('VOIDED', DateTime(2026, 3, 5, 12), 'INCOME', 999,
        voided: true);
    await insert('UPI', DateTime(2026, 4, 5, 12), 'INCOME', 999, mode: 'UPI');

    final snapshot =
        await CashBookPeriodRepository(db: db).watchHistory().first;
    expect(snapshot.months.map((month) => '${month.year}-${month.month}'),
        ['2021-4', '2025-8', '2026-1', '2026-2', '2026-9']);
    expect(snapshot.years.map((year) => year.year), [2021, 2025, 2026]);

    final january = snapshot.months[2];
    expect(january.openingBalance, 130);
    expect(january.cashIn, 67);
    expect(january.cashOut, 10);
    expect(january.closingBalance, 187);
    expect(january.transactionCount, 3);

    final year2026 = snapshot.years.last;
    expect(year2026.openingBalance, 130);
    expect(year2026.cashIn, 110);
    expect(year2026.cashOut, 35);
    expect(year2026.closingBalance, 205);
    expect(year2026.transactionCount, 6);
  });
}
